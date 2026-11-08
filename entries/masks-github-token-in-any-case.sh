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
if [ "$2" = 'print' ]; then
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
for key in github_token GITHUB_TOKEN Github_Token; do
    env \
        GITHUB_WORKSPACE="${tmp}" \
        INPUT_FACTBASE=test.fb \
        INPUT_OUTPUT=output \
        INPUT_VERBOSE=true \
        INPUT_OPTIONS="${key}=ghp_SeCrEt123" \
        'INPUT_GITHUB-TOKEN=ghs_default' \
        LATEST_VERSION=0.0.0 \
        JUDGES="${judges}" \
        "${SELF}/entry.sh" "${SELF}" > "${tmp}/log.txt" 2>&1 || true
    if ! grep -Fxq '::add-mask::ghp_SeCrEt123' "${tmp}/log.txt"; then
        echo "ERROR: the token of the '${key}' option is not masked"
        cat "${tmp}/log.txt"
        exit 1
    fi
    if grep -Fq 'ghp_secret123' "${tmp}/log.txt"; then
        echo "ERROR: a lower-case copy of the token of the '${key}' option is printed"
        cat "${tmp}/log.txt"
        exit 1
    fi
done
