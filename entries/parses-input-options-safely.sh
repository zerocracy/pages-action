#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval test.fb "\$fb.insert" > /dev/null

# Set INPUT_OPTIONS with leading/trailing whitespace and special characters
# The old echo|xargs approach would strip double quotes from key="value",
# producing key=value instead (xargs treats " as quoting characters).
# The new POSIX parameter expansion preserves the original content.
# We use $'...' to embed literal newlines and quotes:
#   line 1: "  testing=yes  "  (has leading/trailing spaces)
#   line 2: 'key="value"'      (has double quotes that xargs would strip)
INPUT_OPTIONS=$'  testing=yes  \nkey="value"\n'

env "GITHUB_WORKSPACE=$(pwd)" \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  "INPUT_OPTIONS=${INPUT_OPTIONS}" \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

grep "The 'github-token' plugin parameter is not set" log.txt

[ -e 'output/test.yaml' ]
[ -e 'output/test.xml' ]
[ -e 'output/test.json' ]
[ -e 'output/test.html' ]
[ -e 'output/test-vitals.html' ]
[ -e 'output/test-badge.svg' ]
