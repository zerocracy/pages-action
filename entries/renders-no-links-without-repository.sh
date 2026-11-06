#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval test.fb "\$fb.insert" > /dev/null

env -u GITHUB_REPOSITORY -u GITHUB_REPOSITORY_OWNER \
  "GITHUB_WORKSPACE=$(pwd)" \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

grep -F "the page will have no absolute links" 'log.txt'
[ -e 'output/test-vitals.html' ]
if grep -F '.github.io' 'output/test-vitals.html'; then
  echo 'The page links to a made-up GitHub Pages URL'
  exit 1
fi
