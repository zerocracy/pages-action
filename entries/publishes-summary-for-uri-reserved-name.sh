#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE

name='team%20stats#1'
bundle exec judges eval "${name}.fb" "\$fb.insert" > /dev/null

env "GITHUB_WORKSPACE=$(pwd)" \
  "INPUT_FACTBASE=${name}.fb" \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

grep "The factbase name is: '${name}'" 'log.txt'

[ -e "output/${name}-vitals.json" ]

diff <(find output -mindepth 1 -printf "%P\n" | LC_ALL=C sort) \
  <(for s in .yaml .xml .json .html -vitals.html -vitals.json -badge.svg; do echo "${name}${s}"; done | LC_ALL=C sort)

node -e '
const assert = require("node:assert/strict");
const fs = require("node:fs");
const summary = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
assert.equal(summary.count, 0);
' "output/${name}-vitals.json"
