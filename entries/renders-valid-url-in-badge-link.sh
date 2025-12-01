#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval test.fb "\$fb.insert" > /dev/null

env "GITHUB_WORKSPACE=$(pwd)" \
  'INPUT_URL=https://foo.com/bar' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_LOGO=' \
  'INPUT_ADLESS=true' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

grep 'https://foo.com/bar/test-badge.svg' 'output/test-vitals.html'
grep 'https://foo.com/bar/test-vitals.html' 'output/test-vitals.html'
