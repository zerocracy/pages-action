#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval test.fb \
    "f = \$fb.insert; f.what = 'assessment'; f.text = 'Exported assessment'; f.when = Time.utc(2024, 7, 1)" > /dev/null

env "GITHUB_WORKSPACE=$(pwd)" \
    'INPUT_FACTBASE=test.fb' \
    'INPUT_OUTPUT=output' \
    'INPUT_VERBOSE=false' \
    'INPUT_COLUMNS=what,text' \
    'INPUT_OPTIONS=testing=yes' \
    "${SELF}/entry.sh" 2>&1 | tee log.txt

for format in yaml xml json html; do
    grep 'latest-assessment' "output/test.${format}"
done
