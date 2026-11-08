#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval test.fb "\$fb.insert" > /dev/null
unset BUNDLE_GEMFILE

workspace=$(pwd)
(
  cd "${SELF}"
  env "GITHUB_WORKSPACE=${workspace}" \
    'INPUT_FACTBASE=test.fb' \
    'INPUT_OUTPUT=output' \
    'INPUT_VERBOSE=false' \
    ./entry.sh
) 2>&1 | tee log.txt

[ -e 'output/test.yaml' ]
[ -e 'output/test.xml' ]
[ -e 'output/test.json' ]
[ -e 'output/test.html' ]
[ -e 'output/test-vitals.html' ]
[ -e 'output/test-badge.svg' ]
