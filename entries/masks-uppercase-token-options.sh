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
if [ "$1" = '--verbose' ]; then
    shift
fi
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
    INPUT_VERBOSE=true \
    INPUT_OPTIONS=$'GITHUB_TOKEN=fixture_first\ngithub_token=fixture_second' \
    'INPUT_GITHUB-TOKEN=ghs_default' \
    LATEST_VERSION=0.0.0 \
    JUDGES="${judges}" \
    JUDGES_UPDATE_ARGS="${tmp}/update.args" \
    "${SELF}/entry.sh" "${SELF}" > "${tmp}/log.txt" 2>&1 || true
for token in fixture_first fixture_second; do
    if ! grep -Fxq "::add-mask::${token}" "${tmp}/log.txt"; then
        echo "ERROR: every token value must be masked"
        exit 1
    fi
    first=$(grep -F "${token}" "${tmp}/log.txt" | head -n 1)
    if [ "${first}" != "::add-mask::${token}" ]; then
        echo "ERROR: a token appeared before its mask"
        exit 1
    fi
done
if ! grep -Fxq -- '--option=GITHUB_TOKEN=fixture_first' "${tmp}/update.args"; then
    echo "ERROR: the uppercase token option must reach judges"
    exit 1
fi
if grep -Fq 'ghs_default' "${tmp}/update.args"; then
    echo "ERROR: the default token must not replace supplied options"
    exit 1
fi
