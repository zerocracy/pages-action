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
  'INPUT_PALETTE=dark' \
  'INPUT_ADLESS=false' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

grep '<html class="palette-dark">' 'output/test-vitals.html'

env "GITHUB_WORKSPACE=$(pwd)" \
  'GITHUB_REPOSITORY=foo/bar' \
  'GITHUB_REPOSITORY_OWNER=foo' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_PALETTE=mild' \
  'INPUT_ADLESS=false' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

grep '<html class="palette-mild">' 'output/test-vitals.html'

env "GITHUB_WORKSPACE=$(pwd)" \
  'GITHUB_REPOSITORY=foo/bar' \
  'GITHUB_REPOSITORY_OWNER=foo' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_PALETTE=classic' \
  'INPUT_ADLESS=false' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

grep '<html class="palette-classic">' 'output/test-vitals.html'

env "GITHUB_WORKSPACE=$(pwd)" \
  'GITHUB_REPOSITORY=foo/bar' \
  'GITHUB_REPOSITORY_OWNER=foo' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_ADLESS=false' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

grep '<html class="palette-classic">' 'output/test-vitals.html'
