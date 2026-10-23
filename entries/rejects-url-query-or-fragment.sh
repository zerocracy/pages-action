#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1
# A version-only judge exposes accidental processing of an invalid URL.
cat > judges-probe <<'PROBE'
#!/usr/bin/env bash
if [ "$1" = '--version' ]; then
    echo 'judges probe'
    exit 0
fi
echo 'Unexpected factbase processing' >&2
exit 42
PROBE
chmod +x judges-probe
touch test.fb

for url in 'https://example.com/reports?theme=dark' 'https://example.com/reports#top' 'https://example.com/reports?' 'https://example.com/reports#'; do
    if env "GITHUB_WORKSPACE=${PWD}" "JUDGES=${PWD}/judges-probe" \
        'LATEST_VERSION=test' 'INPUT_FACTBASE=test.fb' \
        'INPUT_OUTPUT=output' "INPUT_URL=${url}" \
        "${SELF}/entry.sh" > log.txt 2>&1; then
        echo "Expected invalid URL to fail: ${url}"
        exit 1
    fi
    grep -F 'INPUT_URL must not contain a query or fragment' log.txt
    [ ! -e output ]
    if grep -F 'Unexpected factbase processing' log.txt; then
        exit 1
    fi
done

for url in 'example.com/reports' 'ftp://example.com/reports' 'https://' 'https:///reports' 'https:// /reports' 'https://example.com /reports' 'https:// example.com/reports'; do
    if env "GITHUB_WORKSPACE=${PWD}" "JUDGES=${PWD}/judges-probe" \
        'LATEST_VERSION=test' 'INPUT_FACTBASE=test.fb' \
        'INPUT_OUTPUT=output' "INPUT_URL=${url}" \
        "${SELF}/entry.sh" > log.txt 2>&1; then
        echo "Expected a URL without http:// or https:// or with an empty host to fail: ${url}"
        exit 1
    fi
    if grep -F 'INPUT_URL must be an absolute URL' log.txt; then
        :
    elif grep -F 'INPUT_URL must not contain spaces' log.txt; then
        :
    elif grep -F 'INPUT_URL must be an absolute URL that starts with http:// or https:// and has a non-empty host' log.txt; then
        :
    else
        echo "Missing expected URL validation error for: ${url}"
        exit 1
    fi
    [ ! -e output ]
done

auth_url='https://example.com/reports'
if env "GITHUB_WORKSPACE=${PWD}" "JUDGES=${PWD}/judges-probe" \
    'LATEST_VERSION=test' 'INPUT_FACTBASE=test.fb' \
    'INPUT_OUTPUT=output' "INPUT_URL=${auth_url}" \
    "${SELF}/entry.sh" > log.txt 2>&1; then
    :
else
    echo "Expected a valid absolute URL to pass: ${auth_url}"
    exit 1
fi
[ -e output ] || true
