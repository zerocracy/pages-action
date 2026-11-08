#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

touch test.fb
cat > judges.sh << 'STUB'
#!/usr/bin/env bash
if [[ " $* " == *' print '* ]]; then
  printf '%s\n' "$@" >> print.args
fi
if [[ " $* " == *' update '* ]]; then
  exit 3
fi
STUB
chmod a+x judges.sh

env "GITHUB_WORKSPACE=$(pwd)" \
  "JUDGES=$(pwd)/judges.sh" \
  'LATEST_VERSION=0.0.0' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_COLUMNS= when, what ,repository ' \
  'INPUT_HIGHLIGHTED=what ,  who' \
  'INPUT_HIDDEN=_id, _time,  _version' \
  "${SELF}/entry.sh" "${SELF}" > log.txt 2>&1 || true
cat log.txt print.args

grep -A1 -Fx -- '--highlighted' print.args | grep -Fxq 'what,who'
grep -A1 -Fx -- '--hidden' print.args | grep -Fxq '_id,_time,_version'
test "$(grep -A1 -Fx -- '--columns' print.args | grep -c -Fx 'when,what,repository')" -eq 4
