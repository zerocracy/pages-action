#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval test.fb "\$fb.insert" > /dev/null

for pair in 'INPUT_TIMEOUT=abc' 'INPUT_TIMEOUT=0' 'INPUT_LIFETIME=abc' 'INPUT_LIFETIME=0'; do
  set +e
  env "GITHUB_WORKSPACE=$(pwd)" \
    'INPUT_FACTBASE=test.fb' \
    'INPUT_OUTPUT=output' \
    'INPUT_VERBOSE=false' \
    "${pair}" \
    "${SELF}/entry.sh" 2>&1 | tee log.txt
  exit_code=$?
  set -e
  if [ $exit_code -eq 0 ]; then
    echo "ERROR: Script should have failed with ${pair}"
    exit 1
  fi
  grep "${pair%%=*} must be a positive integer" log.txt
done
