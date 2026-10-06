#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1
max_minutes=153722867280912930
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
    exit 77
fi
exit 1
JUDGES
chmod +x "${judges}"

run_case() {
    local name=$1
    local timeout=$2
    local lifetime=$3
    local work="${tmp}/${name}"
    mkdir -p "${work}"
    : > "${work}/test.fb"
    env \
        GITHUB_WORKSPACE="${work}" \
        INPUT_FACTBASE=test.fb \
        INPUT_OUTPUT=output \
        INPUT_VERBOSE=false \
        INPUT_TIMEOUT="${timeout}" \
        INPUT_LIFETIME="${lifetime}" \
        LATEST_VERSION=0.0.0 \
        JUDGES="${judges}" \
        JUDGES_UPDATE_ARGS="${work}/update.args" \
        "${SELF}/entry.sh" "${SELF}" > "${work}/log.txt" 2>&1
}

assert_rejected() {
    local input=$1
    local value=$2
    local expected="${input} must not exceed ${max_minutes} minutes, got: ${value}"
    local work="${tmp}/reject-${input}-${value}"
    local timeout=1
    local lifetime=1
    if [ "${input}" = 'INPUT_TIMEOUT' ]; then
        timeout=${value}
    else
        lifetime=${value}
    fi
    if run_case "reject-${input}-${value}" "${timeout}" "${lifetime}"; then
        echo "ERROR: script should reject ${input}=${value}"
        exit 1
    fi
    if ! grep -Fxq "${expected}" "${work}/log.txt"; then
        echo "ERROR: expected exact error: ${expected}"
        cat "${work}/log.txt"
        exit 1
    fi
    if [ -e "${work}/update.args" ]; then
        echo "ERROR: judges update ran for ${input}=${value}"
        exit 1
    fi
}

for input in INPUT_TIMEOUT INPUT_LIFETIME; do
    for value in \
        153722867280912931 \
        9223372036854775807 \
        18446744073709551617 \
        99999999999999999999999999999999999999999999999999999999999999999999999999999999; do
        assert_rejected "${input}" "${value}"
    done
done

if run_case accepted-bound "${max_minutes}" "${max_minutes}"; then
    exit_code=0
else
    exit_code=$?
fi
if [ "${exit_code:-0}" -ne 77 ]; then
    echo "ERROR: expected judges update sentinel exit 77 at maximum bound, got ${exit_code:-0}"
    exit 1
fi
args="${tmp}/accepted-bound/update.args"
timeout_seconds=$(awk '$0 == "--timeout" { getline; print; exit }' "${args}")
lifetime_seconds=$(awk '$0 == "--lifetime" { getline; print; exit }' "${args}")
if [ "${timeout_seconds}" != 9223372036854775800 ] || [ "${lifetime_seconds}" != 9223372036854775800 ]; then
    echo "ERROR: maximum bound was not forwarded as expected: timeout=${timeout_seconds}, lifetime=${lifetime_seconds}"
    exit 1
fi

if run_case defaults '' ''; then
    exit_code=0
else
    exit_code=$?
fi
if [ "${exit_code:-0}" -ne 77 ]; then
    echo "ERROR: expected judges update sentinel exit 77 for defaults, got ${exit_code:-0}"
    exit 1
fi
args="${tmp}/defaults/update.args"
timeout_seconds=$(awk '$0 == "--timeout" { getline; print; exit }' "${args}")
lifetime_seconds=$(awk '$0 == "--lifetime" { getline; print; exit }' "${args}")
if [ "${timeout_seconds}" != 180 ] || [ "${lifetime_seconds}" != 300 ]; then
    echo "ERROR: defaults were not forwarded as expected: timeout=${timeout_seconds}, lifetime=${lifetime_seconds}"
    exit 1
fi
