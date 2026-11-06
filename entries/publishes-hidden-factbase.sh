#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval .stats.fb "\$fb.insert" > /dev/null

env "GITHUB_WORKSPACE=$(pwd)" \
  'INPUT_FACTBASE=.stats.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

grep "The factbase name is: 'stats'" 'log.txt'

[ -e 'output/stats.yaml' ]
[ -e 'output/stats.xml' ]
[ -e 'output/stats.json' ]
[ -e 'output/stats.html' ]
[ -e 'output/stats-vitals.html' ]
[ -e 'output/stats-badge.svg' ]
