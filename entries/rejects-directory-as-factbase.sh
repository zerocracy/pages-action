#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

mkdir cache.fb
cat > judges.sh << 'STUB'
#!/usr/bin/env bash
exit 0
STUB
chmod a+x judges.sh

code=0
env "GITHUB_WORKSPACE=$(pwd)" \
  "JUDGES=$(pwd)/judges.sh" \
  'LATEST_VERSION=0.0.0' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  "${SELF}/entry.sh" "${SELF}" > auto.txt 2>&1 || code=$?
cat auto.txt
test "${code}" -eq 1
grep -F 'ERROR: No .fb files found in the current directory.' auto.txt

code=0
env "GITHUB_WORKSPACE=$(pwd)" \
  "JUDGES=$(pwd)/judges.sh" \
  'LATEST_VERSION=0.0.0' \
  'INPUT_FACTBASE=cache.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  "${SELF}/entry.sh" "${SELF}" > explicit.txt 2>&1 || code=$?
cat explicit.txt
test "${code}" -eq 1
grep -F "ERROR: The factbase 'cache.fb' is not a file." explicit.txt
