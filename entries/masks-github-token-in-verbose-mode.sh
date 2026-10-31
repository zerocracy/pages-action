#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

touch test.fb
cat > judges.sh << 'STUB'
#!/usr/bin/env bash
exit 0
STUB
chmod a+x judges.sh

env "GITHUB_WORKSPACE=$(pwd)" \
  "JUDGES=$(pwd)/judges.sh" \
  'LATEST_VERSION=0.0.0' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=true' \
  'INPUT_GITHUB-TOKEN=ghs_SECRET' \
  "${SELF}/entry.sh" "${SELF}" > log.txt 2>&1 || true
cat log.txt

test "$(grep -F 'ghs_SECRET' log.txt | head -1)" = '::add-mask::ghs_SECRET'
