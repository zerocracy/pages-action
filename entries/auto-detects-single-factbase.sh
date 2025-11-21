#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval test.fb "\$fb.insert" > /dev/null

env "GITHUB_WORKSPACE=$(pwd)" \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_COLUMNS=details' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

grep "No factbase parameter provided, looking for" 'log.txt'
grep "Auto-detected factbase: test.fb" 'log.txt'

[ -e 'output/test.yaml' ]
[ -e 'output/test.xml' ]
[ -e 'output/test.json' ]
[ -e 'output/test.html' ]
[ -e 'output/test-vitals.html' ]
[ -e 'output/test-badge.svg' ]
