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

for url in 'https://example.com:abc/reports' 'https://example.com:65536/reports' 'https://[::1/reports'; do
    if env "GITHUB_WORKSPACE=${PWD}" "JUDGES=${PWD}/judges-probe" \
        'LATEST_VERSION=test' 'INPUT_FACTBASE=test.fb' \
        'INPUT_OUTPUT=output' "INPUT_URL=${url}" \
        "${SELF}/entry.sh" > log.txt 2>&1; then
        echo "Expected malformed URL authority to fail: ${url}"
        exit 1
    fi
    grep -F 'INPUT_URL must be an absolute URL that starts with http:// or https://' log.txt
    [ ! -e output ]
    if grep -F 'Unexpected factbase processing' log.txt; then
        exit 1
    fi
done

for url in 'https://example.com/reports' 'https://example.com:/reports' \
    'https://example.com:65535/reports' 'https://example.com:00080/reports' \
    'https://example.com:000000000080/reports' 'https://example.com:0/reports' \
    'https://example.com:443/reports' 'https://[::1]/reports' \
    'https://[::1]:443/reports' 'https://user:pass@example.com/reports'; do
    rm -rf output
    env "GITHUB_WORKSPACE=${PWD}" "JUDGES=${PWD}/judges-probe" \
        'LATEST_VERSION=test' 'INPUT_FACTBASE=test.fb' \
        'INPUT_OUTPUT=output' "INPUT_URL=${url}" \
        "${SELF}/entry.sh" > log.txt 2>&1 || true
    grep -F 'Unexpected factbase processing' log.txt
    if grep -F 'INPUT_URL must be an absolute URL that starts with http:// or https://' log.txt; then
        echo "Expected valid URL authority to pass: ${url}"
        exit 1
    fi
done
