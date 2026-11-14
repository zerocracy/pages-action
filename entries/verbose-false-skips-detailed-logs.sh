#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval test.fb "\$fb.insert" > /dev/null

# A probe in front of "judges" records its arguments and GLI_DEBUG, one per line.
args="${PWD}/judges-args.txt"
cat > judges-probe <<PROBE
#!/usr/bin/env bash
printf '%s\n' "\$@" "GLI_DEBUG=\${GLI_DEBUG}" >> '${args}'
exec bundle exec judges "\$@"
PROBE
chmod +x judges-probe

env "GITHUB_WORKSPACE=$(pwd)" \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  "JUDGES=${PWD}/judges-probe" \
  "${SELF}/entry.sh" 2>&1 | tee log.txt

grep "Since 'verbose' is not set to 'true', you won't see detailed logs" log.txt

if grep -E '^\++ ' log.txt; then
  echo 'There must be no shell trace in the log'
  exit 1
fi

grep -Fx -- 'update' "${args}"
if grep -Fx -e '--verbose' -e 'GLI_DEBUG=true' "${args}"; then
  echo 'The judges must not be started in verbose mode'
  exit 1
fi
