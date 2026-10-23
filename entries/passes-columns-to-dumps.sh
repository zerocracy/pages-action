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
    prev=''
    for arg in "$@"; do
        if [ "${prev}" = '--format' ]; then
            format=${arg}
        fi
        prev=${arg}
        output=${arg}
    done
    printf '%s\n' "$@" > "${JUDGES_PRINT_ARGS}/${format}.args"
    touch "${output}"
    exit 0
fi
if [ "$1" = 'update' ]; then
    exit 77
fi
exit 1
JUDGES
chmod +x "${judges}"

work="${tmp}/work"
mkdir -p "${work}" "${tmp}/args"
: > "${work}/test.fb"
if env \
    GITHUB_WORKSPACE="${work}" \
    INPUT_FACTBASE=test.fb \
    INPUT_OUTPUT=output \
    INPUT_VERBOSE=false \
    INPUT_COLUMNS=what,who \
    INPUT_HIGHLIGHTED=award \
    INPUT_HIDDEN=_id \
    LATEST_VERSION=0.0.0 \
    JUDGES="${judges}" \
    JUDGES_PRINT_ARGS="${tmp}/args" \
    "${SELF}/entry.sh" "${SELF}" > "${tmp}/log.txt" 2>&1; then
    exit_code=0
else
    exit_code=$?
fi
if [ "${exit_code}" -ne 77 ]; then
    echo "ERROR: expected judges update sentinel exit 77, got ${exit_code}"
    cat "${tmp}/log.txt"
    exit 1
fi
for f in yaml xml json html; do
    args="${tmp}/args/${f}.args"
    if [ ! -e "${args}" ]; then
        echo "ERROR: the ${f} dump was not printed"
        exit 1
    fi
    for pair in --columns=what,who --highlighted=award --hidden=_id; do
        option=${pair%%=*}
        expected=${pair#*=}
        actual=$(awk -v o="${option}" '$0 == o { getline; print; exit }' "${args}")
        if [ "${actual}" != "${expected}" ]; then
            echo "ERROR: the ${f} dump got ${option} '${actual}' instead of '${expected}'"
            cat "${args}"
            exit 1
        fi
    done
done
