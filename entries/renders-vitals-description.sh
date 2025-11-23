#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE

# Create a test factbase with facts at different dates
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

# Set today to 2024-07-05T00:00:00Z (256 days after 2023-10-23)
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

# Verify the vitals HTML was generated
test -f 'output/test-vitals.html'

# Verify that the old fact (2023-10-22) is excluded from calculations
# Sum should be 30 (10 + 20), not 130 (10 + 20 + 100)
grep -q '30 total points earned' 'output/test-vitals.html' || {
  echo "ERROR: Expected '30 total points earned' but found:"
  grep 'total points earned' 'output/test-vitals.html'
  exit 1
}

# Verify average is calculated correctly (30 / 2 = 15.0)
grep -qE '15\.00 average points per task' 'output/test-vitals.html' || {
  echo "ERROR: Expected '15.00 average points per task' but found:"
  grep 'average points per task' 'output/test-vitals.html'
  exit 1
}

# Verify only 1 contributor is counted (user2 excluded due to date)
grep -q '1 contributors' 'output/test-vitals.html' || {
  echo "ERROR: Expected '1 contributors' but found:"
  grep 'contributors' 'output/test-vitals.html'
  exit 1
}

echo "✅ Description test passed"

