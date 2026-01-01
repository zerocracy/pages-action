#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE

set +e
env "GITHUB_WORKSPACE=$(pwd)" \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt
exit_code=$?
set -e

if [ $exit_code -eq 0 ]; then
  echo "ERROR: Script should have failed when no .fb files exist"
  echo "Check log.txt for details of the failure"
  exit 1
fi
