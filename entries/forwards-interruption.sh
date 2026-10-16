#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

touch test.fb
cat > judges.sh << 'STUB'
#!/usr/bin/env bash
if [[ " $* " == *' update '* ]]; then
  trap 'echo stopped > stopped.txt; exit 143' TERM
  echo $$ > judges.pid
  sleep 30 &
  wait
  echo finished > finished.txt
fi
STUB
chmod a+x judges.sh

# Job control keeps SIGINT at its default in the background job, which a
# non-interactive Bash would otherwise ignore, and no trap could undo it.
set -m
env "GITHUB_WORKSPACE=$(pwd)" \
  "JUDGES=$(pwd)/judges.sh" \
  'LATEST_VERSION=0.0.0' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  "${SELF}/entry.sh" "${SELF}" > log.txt 2>&1 &
entry=$!
for _ in $(seq 1 100); do
  if [ -s judges.pid ]; then
    break
  fi
  sleep 0.1
done
test -s judges.pid
kill -INT "${entry}"
code=0
wait "${entry}" || code=$?
test "${code}" -eq 130
test -e stopped.txt
test ! -e finished.txt
if kill -0 "$(cat judges.pid)" 2>/dev/null; then
  exit 1
fi
