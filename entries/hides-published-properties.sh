#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE

bundle exec judges eval test.fb "
  f = \$fb.insert
  f.what = 'dimensions-of-terrain'
  f.when = Time.utc(2026, 9, 5)
  f.total_repositories = 7
  f.secret_salary = 12345
  f.secret_salary = 67890
  f.salary_public = 'VISIBLE_CONTROL'
  f.visible_types = 7
  f.visible_types = 2.5
  f.visible_types = 'VISIBLE_TYPE_MARKER'
  f = \$fb.insert
  f.what = 'quality-of-service'
  f.when = Time.utc(2026, 9, 5)
  f.n_private_metric = 987654
  f.n_public_metric = 424242
" > /dev/null

env "GITHUB_WORKSPACE=$(pwd)" \
  'GITHUB_REPOSITORY=foo/bar' \
  'GITHUB_REPOSITORY_OWNER=foo' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_COLUMNS=what,when,total_repositories,secret_salary' \
  'INPUT_HIDDEN=_id,_time,_version,secret_salary,n_private_metric' \
  'INPUT_TODAY=2026-09-06T00:00:00Z' \
  'INPUT_ADLESS=true' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  'LATEST_VERSION=0.0.0' \
  "${SELF}/entry.sh" > log.txt 2>&1

for file in output/test.yaml output/test.xml output/test.json output/test.html output/test-vitals.html output/test-badge.svg; do
  for value in 12345 67890 987654; do
    if grep -F -q "${value}" "${file}"; then
      echo "Hidden value '${value}' appears in ${file}" >&2
      exit 1
    fi
  done
done

if grep -F -q 'secret_salary' output/test.yaml output/test.xml output/test.json output/test-vitals.html; then
  echo 'a hidden property name appears outside the HTML column list' >&2
  exit 1
fi
if grep -F -q 'n_private_metric' output/test.yaml output/test.xml output/test.json output/test-vitals.html; then
  echo 'n_private_metric appears in a published file' >&2
  exit 1
fi
if grep -F -q 'title="12345"' output/test.html || grep -F -q 'title="67890"' output/test.html; then
  echo 'the HTML dump keeps a hidden salary in a title attribute' >&2
  exit 1
fi

grep -F -q 'VISIBLE_CONTROL' output/test.yaml
grep -F -q 'VISIBLE_CONTROL' output/test.xml
grep -F -q 'VISIBLE_CONTROL' output/test.json
grep -F -q 'VISIBLE_CONTROL' output/test.html
grep -F -q 'total_repositories' output/test-vitals.html
grep -F -q '424242' output/test-vitals.html

bundle exec ruby -rjson -e '
  facts = JSON.parse(File.read("output/test.json"))
  terrain = facts.find { |fact| fact["what"] == "dimensions-of-terrain" }
  raise "repeated values lost their types" unless terrain["visible_types"] == [7, 2.5, "VISIBLE_TYPE_MARKER"]
  raise "the timestamp was not preserved" unless terrain["when"].include?("2026-09-05")
  raise "secret_salary leaked into JSON" if terrain.key?("secret_salary")
  qos = facts.find { |fact| fact["what"] == "quality-of-service" }
  raise "n_public_metric was dropped" unless qos["n_public_metric"] == 424242
  raise "n_private_metric leaked into JSON" if qos.key?("n_private_metric")
'

bundle exec judges eval test.fb "
  raise 'source factbase lost secret_salary' if \$fb.query('(eq secret_salary 12345)').each.to_a.empty?
  raise 'source factbase lost the second salary' if \$fb.query('(eq secret_salary 67890)').each.to_a.empty?
  raise 'source factbase lost n_private_metric' if \$fb.query('(eq n_private_metric 987654)').each.to_a.empty?
" > /dev/null

diff <(find output -mindepth 1 -printf '%P\n' | LC_ALL=C sort) \
  <(printf '%s\n' test.yaml test.xml test.json test.html test-vitals.html test-badge.svg | LC_ALL=C sort)
