#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval test.fb "\$fb.insert" > /dev/null

summary="$(pwd)/summary.md"
: > "${summary}"

env "GITHUB_WORKSPACE=$(pwd)" \
  'GITHUB_REPOSITORY=foo/bar' \
  'GITHUB_REPOSITORY_OWNER=foo' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_URL=https://example.com/reports' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  'LATEST_VERSION=0.0.0' \
  "GITHUB_STEP_SUMMARY=${summary}" \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

grep 'Run summary written to' 'log.txt'
grep -F '### test' "${summary}"
grep -F 'contributors' "${summary}"
grep -F '[Vitals page](https://example.com/reports/test-vitals.html)' "${summary}"
grep -F '[Badge](https://example.com/reports/test-badge.svg)' "${summary}"
