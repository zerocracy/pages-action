#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

touch .stats.fb
cat > judges.sh << 'STUB'
#!/usr/bin/env bash
if [ "$1" = '--version' ]; then
  exit 0
fi
exit 1
STUB
chmod a+x judges.sh

env "GITHUB_WORKSPACE=$(pwd)" \
  "JUDGES=$(pwd)/judges.sh" \
  'LATEST_VERSION=0.0.0' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  "${SELF}/entry.sh" "${SELF}" > log.txt 2>&1 || true

grep 'Auto-detected factbase: .stats.fb' 'log.txt'
