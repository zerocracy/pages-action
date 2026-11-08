#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval test.fb "\$fb.insert" > /dev/null

for repo in foo/foo.github.io Foo/foo.github.io; do
  rm -rf output
  env "GITHUB_WORKSPACE=$(pwd)" \
    "GITHUB_REPOSITORY=${repo}" \
    "GITHUB_REPOSITORY_OWNER=${repo%%/*}" \
    'INPUT_FACTBASE=test.fb' \
    'INPUT_OUTPUT=output' \
    'INPUT_VERBOSE=false' \
    'INPUT_LOGO=' \
    'INPUT_ADLESS=true' \
    'INPUT_GITHUB-TOKEN=THETOKEN' \
    "${SELF}/entry.sh" 2>&1 | tee log.txt
  grep -i 'https://foo.github.io/test-vitals.html' 'output/test-vitals.html'
  if grep -i 'foo.github.io/foo.github.io' 'output/test-vitals.html'; then
    echo "The URL of the page has the name of the repository in it, for ${repo}"
    exit 1
  fi
done
