#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1
BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE

bundle exec judges eval test.fb "
  older = \$fb.insert
  older.what = 'assessment'
  older.when = Time.utc(2024, 7, 1)
  older.text = 'Older assessment.'
  newer = \$fb.insert
  newer.what = 'assessment'
  newer.when = Time.utc(2024, 9, 15)
  newer.text = 'Latest assessment.'
" > /dev/null

env "GITHUB_WORKSPACE=$(pwd)" \
  'GITHUB_REPOSITORY=foo/bar' \
  'GITHUB_REPOSITORY_OWNER=foo' \
  'LATEST_VERSION=0.0.0' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_COLUMNS=details' \
  'INPUT_ADLESS=true' \
  'INPUT_TODAY=2024-09-16T00:00:00Z' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

for format in yaml xml json html; do
  grep -F 'latest-assessment' "output/test.${format}"
done
