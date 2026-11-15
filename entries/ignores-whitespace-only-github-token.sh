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
    'INPUT_GITHUB-TOKEN=   ' \
    LATEST_VERSION=0.0.0 \
    JUDGES="${judges}" \
    JUDGES_UPDATE_ARGS="${tmp}/update.args" \
    "${SELF}/entry.sh" "${SELF}" > "${tmp}/log.txt" 2>&1 || true
if grep -Fq 'github_token=' "${tmp}/update.args" 2>/dev/null; then
    echo "ERROR: whitespace-only INPUT_GITHUB-TOKEN must not become --option=github_token"
    cat "${tmp}/update.args" "${tmp}/log.txt"
    exit 1
fi
if ! grep -Fq "The 'github-token' plugin parameter is not set" "${tmp}/log.txt"; then
    echo "ERROR: whitespace-only INPUT_GITHUB-TOKEN must be treated as unset"
    cat "${tmp}/log.txt"
    exit 1
fi
