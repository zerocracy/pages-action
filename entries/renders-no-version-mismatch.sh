#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval test.fb "\$fb.insert" > /dev/null

env "GITHUB_WORKSPACE=$(pwd)" \
  'GITHUB_REPOSITORY=foo/bar' \
  'GITHUB_REPOSITORY_OWNER=foo' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_LOGO=' \
  'INPUT_ADLESS=true' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  'LATEST_VERSION=0.0.0' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

if grep -q "while the latest version is" 'output/test-vitals.html'; then
    echo "ERROR: Warning banner should not appear when versions match"
    exit 1
fi
grep "test-vitals" 'output/test-vitals.html'
