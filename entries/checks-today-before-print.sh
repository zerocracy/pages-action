#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

touch test.fb
cat > judges.sh << 'STUB'
#!/usr/bin/env bash
echo "$1" >> calls.txt
STUB
chmod a+x judges.sh

code=0
env "GITHUB_WORKSPACE=$(pwd)" \
  "JUDGES=$(pwd)/judges.sh" \
  'LATEST_VERSION=0.0.0' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_TODAY=yesterday' \
  "${SELF}/entry.sh" "${SELF}" > log.txt 2>&1 || code=$?
[ "${code}" -ne 0 ]
grep -F "The 'today' input must be an ISO-8601 date-time" log.txt
if grep -Fx 'print' calls.txt; then
  echo 'The factbase is printed before the today input is checked'
  exit 1
fi
