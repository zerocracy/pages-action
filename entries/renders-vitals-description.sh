#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE

bundle exec judges eval test.fb "
  \$fb.insert
  f = \$fb.insert
  f.when = '2024-07-05T00:00:00Z'
  f.award = 10
  f.who = 12345
  f.who_name = 'user1'
  f = \$fb.insert
  f.when = '2024-06-26T00:00:00Z'
  f.award = 20
  f.who = 12345
  f.who_name = 'user1'
  f = \$fb.insert
  f.when = '2023-10-22T00:00:00Z'
  f.award = 100
  f.who = 67890
  f.who_name = 'user2'
" > /dev/null

env "GITHUB_WORKSPACE=$(pwd)" \
  'GITHUB_REPOSITORY=foo/bar' \
  'GITHUB_REPOSITORY_OWNER=foo' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_LOGO=' \
  'INPUT_ADLESS=false' \
  'INPUT_TODAY=2024-07-05T00:00:00Z' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

test -f 'output/test-vitals.html'

grep 'The "test" product is supervised by Zerocracy:' 'output/test-vitals.html'
grep '\+15\.0 average points per task' 'output/test-vitals.html'
grep '30 total points earned' 'output/test-vitals.html'
grep '1 contributors\.' 'output/test-vitals.html'
grep -E 'The "[^"]*" product is supervised by Zerocracy:.*contributors\.' 'output/test-vitals.html'


rm -f test.fb
