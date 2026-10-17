#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

touch test.fb
cat > judges.sh << 'STUB'
#!/usr/bin/env bash
if [[ " $* " == *' update '* ]]; then
  exit 3
fi
if [[ " $* " == *' print '* ]]; then
  for arg in "$@"; do
    output=${arg}
  done
  echo new > "${output}"
fi
STUB
chmod a+x judges.sh

mkdir output
for f in test.yaml test.xml test.json test.html test-vitals.html test-badge.svg; do
  echo old > "output/${f}"
done

code=0
env "GITHUB_WORKSPACE=$(pwd)" \
  "JUDGES=$(pwd)/judges.sh" \
  'LATEST_VERSION=0.0.0' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  "${SELF}/entry.sh" "${SELF}" > log.txt 2>&1 || code=$?
cat log.txt
test "${code}" -eq 3

test "$(find output -mindepth 1 | wc -l)" -eq 6
for f in output/*; do
  test "$(cat "${f}")" = 'old'
done
