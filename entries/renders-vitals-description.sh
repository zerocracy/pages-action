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

if ! grep -qE 'The "test" product is supervised by Zerocracy: \+15\.0 average points per task, 30 total points earned, 1 contributors\.' 'output/test-vitals.html'; then
  echo "ERROR: Expected full description text not found:"
  echo "  Expected: The \"test\" product is supervised by Zerocracy: +15.0 average points per task, 30 total points earned, 1 contributors."
  echo "  Found:"
  grep -oE 'The "[^"]*" product is supervised by Zerocracy:[^<]*contributors\.' 'output/test-vitals.html' || echo "(pattern not found)"
  exit 1
fi


rm -f test.fb

bundle exec judges eval test.fb "
  \$fb.insert
  f = \$fb.insert
  f.when = '2024-07-10T00:00:00Z'
  f.award = 5
  f.who = 11111
  f.who_name = 'alice'
  f = \$fb.insert
  f.when = '2024-07-09T00:00:00Z'
  f.award = 15
  f.who = 22222
  f.who_name = 'bob'
  f = \$fb.insert
  f.when = '2024-07-08T00:00:00Z'
  f.award = 15
  f.who = 22222
  f.who_name = 'bob'
  f = \$fb.insert
  f.when = '2024-07-07T00:00:00Z'
  f.award = 17
  f.who = 33333
  f.who_name = 'charlie'
  f = \$fb.insert
  f.when = '2024-07-06T00:00:00Z'
  f.award = 17
  f.who = 33333
  f.who_name = 'charlie'
" > /dev/null

env "GITHUB_WORKSPACE=$(pwd)" \
  'GITHUB_REPOSITORY=foo/bar' \
  'GITHUB_REPOSITORY_OWNER=foo' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_LOGO=' \
  'INPUT_ADLESS=false' \
  'INPUT_TODAY=2024-07-10T00:00:00Z' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

test -f 'output/test-vitals.html'


if ! grep -qE 'The "test" product is supervised by Zerocracy: \+13\.8 average points per task, 69 total points earned, 3 contributors\.' 'output/test-vitals.html'; then
  echo "ERROR: Expected full description text not found (second test):"
  echo "  Expected: The \"test\" product is supervised by Zerocracy: +13.8 average points per task, 69 total points earned, 3 contributors."
  echo "  Found:"
  grep -oE 'The "[^"]*" product is supervised by Zerocracy:[^<]*contributors\.' 'output/test-vitals.html' || echo "(pattern not found)"
  exit 1
fi

rm -f test.fb
