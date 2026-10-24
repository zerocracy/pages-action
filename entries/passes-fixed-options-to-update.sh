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
    exit 77
fi
exit 1
JUDGES
chmod +x "${judges}"

work="${tmp}/work"
mkdir -p "${work}"
: > "${work}/test.fb"
if env \
    GITHUB_WORKSPACE="${work}" \
    INPUT_FACTBASE=test.fb \
    INPUT_OUTPUT=output \
    INPUT_VERBOSE=false \
    LATEST_VERSION=0.0.0 \
    JUDGES="${judges}" \
    JUDGES_UPDATE_ARGS="${tmp}/update.args" \
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
args="${tmp}/update.args"
cycles=$(awk '$0 == "--max-cycles" { getline; print; exit }' "${args}")
if [ "${cycles}" != 1 ]; then
    echo "ERROR: judges update got --max-cycles '${cycles}' instead of '1'"
    cat "${args}"
    exit 1
fi
for option in --no-log --summary=off --shuffle=; do
    if ! grep -Fxq -- "${option}" "${args}"; then
        echo "ERROR: judges update was started without ${option}"
        cat "${args}"
        exit 1
    fi
done
