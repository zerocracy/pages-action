#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1
tmp=$(mktemp -d)
trap 'rm -rf "${tmp}"' EXIT

judges="${tmp}/judges"
cat > "${judges}" <<'JUDGES'
#!/usr/bin/env bash
set -e
if [ "$1" = '--version' ]; then
    exit 0
fi
if [ "$1" = 'print' ]; then
    for arg in "$@"; do
        output=${arg}
    done
    touch "${output}"
    exit 0
fi
if [ "$1" = 'update' ]; then
    printf '%s\n' "$@" > "${JUDGES_UPDATE_ARGS}"
fi
exit 77
JUDGES
chmod +x "${judges}"

: > "${tmp}/test.fb"
env \
    GITHUB_WORKSPACE="${tmp}" \
    INPUT_FACTBASE=test.fb \
    INPUT_OUTPUT=output \
    INPUT_VERBOSE=false \
    INPUT_OPTIONS='GITHUB_TOKEN=' \
    'INPUT_GITHUB-TOKEN=ghs_default' \
    LATEST_VERSION=0.0.0 \
    JUDGES="${judges}" \
    JUDGES_UPDATE_ARGS="${tmp}/update.args" \
    "${SELF}/entry.sh" "${SELF}" > "${tmp}/log.txt" 2>&1 || true
if ! grep -Fxq -- '--option=github_token=ghs_default' "${tmp}/update.args"; then
    echo "ERROR: empty uppercase GITHUB_TOKEN= must fall back to INPUT_GITHUB-TOKEN"
    cat "${tmp}/update.args" "${tmp}/log.txt"
    exit 1
fi
if grep -Fxq -- '--option=GITHUB_TOKEN=' "${tmp}/update.args"; then
    echo "ERROR: empty GITHUB_TOKEN= must not be forwarded to judges"
    cat "${tmp}/update.args" "${tmp}/log.txt"
    exit 1
fi
if ! grep -Fq "The 'github_token' option is empty, ignoring it" "${tmp}/log.txt"; then
    echo "ERROR: empty uppercase GITHUB_TOKEN= must be ignored like lowercase"
    cat "${tmp}/log.txt"
    exit 1
fi
