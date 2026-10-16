#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

touch test.fb
cat > judges.sh << 'STUB'
#!/usr/bin/env bash
echo "$1" >> calls.txt
if [ "$1" = 'print' ]; then
  for arg in "$@"; do
    output=${arg}
  done
  touch "${output}"
fi
STUB
chmod a+x judges.sh

for today in 'yesterday' '2026-09-07' '2026-09-07 12:00:00'; do
  rm -f calls.txt
  if env "GITHUB_WORKSPACE=$(pwd)" \
    "JUDGES=$(pwd)/judges.sh" \
    'LATEST_VERSION=0.0.0' \
    'INPUT_FACTBASE=test.fb' \
    'INPUT_OUTPUT=output' \
    'INPUT_VERBOSE=false' \
    "INPUT_TODAY=${today}" \
    "${SELF}/entry.sh" "${SELF}" > log.txt 2>&1; then
    echo "Expected a malformed today to fail: ${today}"
    exit 1
  fi
  grep -F "The 'today' input must be an ISO-8601 date-time" log.txt
  if grep -Fx 'update' calls.txt; then
    echo "The judges must not be updated with a malformed today: ${today}"
    exit 1
  fi
done
