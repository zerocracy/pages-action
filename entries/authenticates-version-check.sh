#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval test.fb "\$fb.insert" > /dev/null

# Run with INPUT_GITHUB-TOKEN set — the new code adds this token
# as Authorization header to the GitHub API version check curl request,
# raising the rate limit from 60 to 5000 req/hr.
# The old code ignored INPUT_GITHUB-TOKEN for the version check,
# which caused silent failures in shared CI environments.
env "GITHUB_WORKSPACE=$(pwd)" \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

# Version check should have run (with or without successful API response)
grep "The 'pages-action' 0.0.0 is running" log.txt

# The github-token path in the judges section should also work
grep "The 'github-token' plugin parameter is set" log.txt

[ -e 'output/test.yaml' ]
[ -e 'output/test.xml' ]
[ -e 'output/test.json' ]
[ -e 'output/test.html' ]
[ -e 'output/test-vitals.html' ]
[ -e 'output/test-badge.svg' ]
