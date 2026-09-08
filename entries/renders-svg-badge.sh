#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval test.fb "\$fb.insert" > /dev/null

env "GITHUB_WORKSPACE=$(pwd)" \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_LOGO=' \
  'INPUT_ADLESS=true' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

badge=output/test-badge.svg

grep -q "<svg" "${badge}"
grep -q 'width="93"' "${badge}"
grep -q 'height="20"' "${badge}"
grep -q 'fill="#e05d44"' "${badge}"
grep -q ">avg<" "${badge}"
grep -qE ">[+]0(\.0)?<" "${badge}"
