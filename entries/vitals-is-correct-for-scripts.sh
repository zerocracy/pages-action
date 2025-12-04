#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
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
  'INPUT_ADLESS=false' \
  'INPUT_TODAY=2024-07-05T00:00:00Z' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

echo "vitals should contain <html>"
grep -E '<html.*>' 'output/test-vitals.html'
echo "vitals should contain #generated-time"
grep 'id="generated-time"' 'output/test-vitals.html'
echo "vitals should contain .relative-time"
grep 'class="relative-time"' 'output/test-vitals.html'
echo "vitals should contain <time>"
grep -E '<time.*>on 2024-07-05T00:00:00Z</time>' 'output/test-vitals.html'
echo "<time> should have the title"
grep -E '<time.*title="2024-07-05T00:00:00Z".*>.*</time>' 'output/test-vitals.html'
echo "<time> should have datetime attribute"
grep -E '<time.*datetime="2024-07-05T00:00:00Z">on 2024-07-05T00:00:00Z</time>' 'output/test-vitals.html'
echo "vitals should contain <footer>"
grep -E '<footer.*>' 'output/test-vitals.html' 'output/test-vitals.html'

echo "OK"
