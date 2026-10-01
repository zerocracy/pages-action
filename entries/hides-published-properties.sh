#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
JUDGES='bundle exec judges --offline'
export JUDGES

bundle exec judges eval test.fb "
  f = \$fb.insert
  f.what = 'dimensions-of-terrain'
  f.when = Time.utc(2026, 9, 5)
  f.total_repositories = 7
  f.secret_salary = 12345
  f.secret_salary = 67890
  f.secret_salary_public = 'VISIBLE_CONTROL'
  f.visible_types = 7
  f.visible_types = 2.5
  f.visible_types = 'VISIBLE_TYPE_MARKER'
  f.award = 17
  f.is_human = 1
  f.who_name = 'fixture'
  f = \$fb.insert
  f.what = 'quality-of-service'
  f.when = Time.utc(2026, 9, 5)
  f.n_private_metric = 987654
" > /dev/null

env "GITHUB_WORKSPACE=$(pwd)" \
  'GITHUB_REPOSITORY=foo/bar' \
  'GITHUB_REPOSITORY_OWNER=foo' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_COLUMNS=what,when,total_repositories,secret_salary,secret_salary_public,visible_types' \
  'INPUT_HIDDEN=_id,_time,_version,secret_salary,n_private_metric,award' \
  'INPUT_TODAY=2026-09-06T00:00:00Z' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  'LATEST_VERSION=0.0.0' \
  "${SELF}/entry.sh" > log.txt 2>&1

for file in output/test.yaml output/test.xml output/test.json output/test.html output/test-vitals.html output/test-badge.svg; do
  for value in 12345 67890 987654; do
    if grep -Fq "${value}" "${file}"; then
      echo "Hidden value '${value}' appears in ${file}" >&2
      exit 1
    fi
  done
done

if grep -Eq '(^|[[:space:]])(secret_salary|n_private_metric|award|_id|_time|_version):' output/test.yaml; then
  echo 'a hidden property appears in output/test.yaml' >&2
  exit 1
fi
if grep -Eq '<(secret_salary|n_private_metric|award|_id|_time|_version)([ >])' output/test.xml; then
  echo 'a hidden property appears in output/test.xml' >&2
  exit 1
fi
if grep -Eq '"(secret_salary|n_private_metric|award|_id|_time|_version)"[[:space:]]*:' output/test.json; then
  echo 'a hidden property appears in output/test.json' >&2
  exit 1
fi

if grep -Fq '17 total points earned' output/test-vitals.html; then
  echo 'the hidden award appears in output/test-vitals.html' >&2
  exit 1
fi

grep -Fq 'VISIBLE_CONTROL' output/test.yaml
grep -Fq 'VISIBLE_CONTROL' output/test.xml
grep -Fq 'VISIBLE_CONTROL' output/test.json
grep -Fq 'VISIBLE_CONTROL' output/test.html
bundle exec ruby -rjson -e '
  facts = JSON.parse(File.read("output/test.json"))
  terrain = facts.find { |fact| fact["what"] == "dimensions-of-terrain" }
  raise "repeated values lost their types" unless terrain["visible_types"] == [7, 2.5, "VISIBLE_TYPE_MARKER"]
  raise "the timestamp was not preserved" unless terrain["when"].start_with?("2026-09-05")
'
grep -Eq '>7<' output/test-vitals.html
grep -Eq '>\+0(\.0)?<' output/test-badge.svg

bundle exec judges eval test.fb "
  facts = \$fb.query('(always)').each.to_a
  terrain = facts.find { |f| f['what'].first == 'dimensions-of-terrain' }
  qos = facts.find { |f| f['what'].first == 'quality-of-service' }
  raise 'source factbase lost hidden salaries' unless terrain['secret_salary'] == [12345, 67890]
  raise 'source factbase lost the hidden metric' unless qos['n_private_metric'] == [987654]
  raise 'source factbase lost the hidden award' unless terrain['award'] == [17]
" > /dev/null

printf '%s\n' \
  test-badge.svg \
  test-vitals.html \
  test.html \
  test.json \
  test.xml \
  test.yaml > expected-files.txt
find output -mindepth 1 -maxdepth 1 -exec basename {} \; | sort > actual-files.txt
diff -u expected-files.txt actual-files.txt
