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
exit 77
JUDGES
chmod +x "${judges}"

: > "${tmp}/test.fb"
env \
    GITHUB_WORKSPACE="${tmp}" \
    INPUT_FACTBASE=test.fb \
    INPUT_OUTPUT=output \
    INPUT_VERBOSE=false \
    INPUT_TODAY=2026-10-05T12:00:00 \
    LATEST_VERSION=0.0.0 \
    JUDGES="${judges}" \
    "${SELF}/entry.sh" "${SELF}" > "${tmp}/log.txt" 2>&1 || true
if ! grep -Fxq "The 'today' is set to: '2026-10-05T12:00:00Z'" "${tmp}/log.txt"; then
    echo "ERROR: a today without a zone must be read as UTC"
    cat "${tmp}/log.txt"
    exit 1
fi
for today in 2026-10-05T12:00:00Z 2026-10-05T12:00:00+03:00 2026-10-05T12:00:00-05:00; do
    env \
        GITHUB_WORKSPACE="${tmp}" \
        INPUT_FACTBASE=test.fb \
        INPUT_OUTPUT=output \
        INPUT_VERBOSE=false \
        INPUT_TODAY="${today}" \
        LATEST_VERSION=0.0.0 \
        JUDGES="${judges}" \
        "${SELF}/entry.sh" "${SELF}" > "${tmp}/log.txt" 2>&1 || true
    if ! grep -Fxq "The 'today' is set to: '${today}'" "${tmp}/log.txt"; then
        echo "ERROR: a today with a zone must stay as it is: ${today}"
        cat "${tmp}/log.txt"
        exit 1
    fi
done
