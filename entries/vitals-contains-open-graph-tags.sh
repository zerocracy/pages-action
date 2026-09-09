#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval project.fb "\$fb.insert" > /dev/null

env "GITHUB_WORKSPACE=$(pwd)" \
  'GITHUB_REPOSITORY=foo/bar' \
  'GITHUB_REPOSITORY_OWNER=foo' \
  'INPUT_URL=https://example.com/reports' \
  'INPUT_FACTBASE=project.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_ADLESS=false' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

grep 'meta property="og:title"' 'output/project-vitals.html'
grep 'meta property="og:url" content="https://example.com/reports/project-vitals.html"' 'output/project-vitals.html'
grep -F '[![discipline](https://example.com/reports/project-badge.svg)](https://example.com/reports/project-vitals.html)' 'output/project-vitals.html'
grep 'meta property="og:image"' 'output/project-vitals.html'
grep 'meta property="og:type"' 'output/project-vitals.html'
grep 'meta property="og:description"' 'output/project-vitals.html'
