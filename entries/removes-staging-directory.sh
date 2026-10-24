#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

SELF=$1

BUNDLE_GEMFILE="${SELF}/Gemfile"
export BUNDLE_GEMFILE
bundle exec judges eval test.fb "\$fb.insert" > /dev/null

env "GITHUB_WORKSPACE=$(pwd)" \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  'INPUT_GITHUB-TOKEN=THETOKEN' \
  "${SELF}/entry.sh" 2>&1 | tee log.txt
[ -e 'output/test-vitals.html' ]
if compgen -G 'output/.pages-action.*'; then
  echo 'The staging directory is left in the output after a success'
  exit 1
fi

cat > judges.sh << 'STUB'
#!/usr/bin/env bash
if [ "$1" = 'print' ]; then
  for arg in "$@"; do
    output=${arg}
  done
  touch "${output}"
  exit 0
fi
if [ "$1" = 'update' ]; then
  exit 1
fi
STUB
chmod a+x judges.sh
rm -rf output
code=0
env "GITHUB_WORKSPACE=$(pwd)" \
  "JUDGES=$(pwd)/judges.sh" \
  'LATEST_VERSION=0.0.0' \
  'INPUT_FACTBASE=test.fb' \
  'INPUT_OUTPUT=output' \
  'INPUT_VERBOSE=false' \
  "${SELF}/entry.sh" "${SELF}" > failure.txt 2>&1 || code=$?
[ "${code}" -ne 0 ]
grep 'The staging directory is: output/.pages-action.' failure.txt
if compgen -G 'output/.pages-action.*'; then
  echo 'The staging directory is left in the output after a failure'
  exit 1
fi
