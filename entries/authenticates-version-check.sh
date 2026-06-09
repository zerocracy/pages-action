#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval test.fb "\$fb.insert" > /dev/null

# Create a mock curl that records arguments and returns a fake response.
# This lets us verify the Authorization header is actually passed to the
# GitHub API version check — a real curl call would not reveal this.
mkdir -p "${PWD}/mock"
cat > "${PWD}/mock/curl" << 'MOCKEOF'
#!/bin/bash
echo "$*" >> "${PWD}/curl-args.log"
# Return a valid-looking response so LATEST_VERSION gets parsed
echo '{"tag_name": "v0.1.0"}'
MOCKEOF
chmod +x "${PWD}/mock/curl"

# Prepend mock directory to PATH so entry.sh finds our fake curl first
export PATH="${PWD}/mock:${PATH}"

# Run with token — new code must add Authorization header to the API call
env "GITHUB_WORKSPACE=$(pwd)" \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

# Verify the mock curl was called for the version check
grep "api.github.com/repos/zerocracy/pages-action/releases/latest" curl-args.log

# Verify the Authorization header was passed with the token
grep "Authorization: token THETOKEN" curl-args.log

# Verify version was parsed from the mock response
grep "The 'pages-action' 0.0.0 is running" log.txt

# Verify the token also reaches the judges section
grep "The 'github-token' plugin parameter is set" log.txt

[ -e 'output/test.yaml' ]
[ -e 'output/test.xml' ]
[ -e 'output/test.json' ]
[ -e 'output/test.html' ]
[ -e 'output/test-vitals.html' ]
[ -e 'output/test-badge.svg' ]
