#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

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

for url in \
    'https://user@' \
    'http://user@' \
    'https://user:password@' \
    'http://user:password@' \
    'https://user@/path' \
    'http://user@/path' \
    'https://user:password@/path' \
    'http://user:password@/path' \
    'https://user@:8080' \
    'http://user@:8080' \
    'https://user:password@:8080' \
    'http://user:password@:8080' \
    'https://user@:8080/path' \
    'http://user:password@:8080/path' \
    'https://[]' \
    'http://[]' \
    'https://[]/path' \
    'https://[]:8080' \
    'https://user@[]' \
    'http://user@[]' \
    'https://user:password@[]' \
    'https://user@[]:8080' \
    'https://user:password@[]/path'; do
    if env "GITHUB_WORKSPACE=${PWD}" "JUDGES=${PWD}/judges-probe" \
        'LATEST_VERSION=test' 'INPUT_FACTBASE=test.fb' \
        'INPUT_OUTPUT=output' "INPUT_URL=${url}" \
        "${SELF}/entry.sh" > log.txt 2>&1; then
        echo "Expected URL with missing host to fail: ${url}"
        exit 1
    fi
    grep -F 'INPUT_URL must be an absolute URL' log.txt
    [ ! -e output ]
    if grep -F 'Unexpected factbase processing' log.txt; then
        echo "Probe should not be called for invalid URL: ${url}"
        exit 1
    fi
done

for url in \
    'https://[::1]/reports' \
    'http://[::1]/reports' \
    'https://[2001:db8::1]:8080/reports' \
    'http://[2001:db8::1]:8080/reports' \
    'https://[::1]' \
    'http://[::1]' \
    'https://user@[::1]' \
    'http://user@[::1]' \
    'https://user:password@[::1]:8080/reports' \
    'https://user@[2001:db8::1]:8080/reports' \
    'https://[::ffff:192.0.2.1]/reports'; do
    if env "GITHUB_WORKSPACE=${PWD}" "JUDGES=${PWD}/judges-probe" \
        'LATEST_VERSION=test' 'INPUT_FACTBASE=test.fb' \
        'INPUT_OUTPUT=output' "INPUT_URL=${url}" \
        "${SELF}/entry.sh" > log.txt 2>&1; then
        echo "Expected probe failure for valid URL: ${url}"
        exit 1
    fi
    if grep -F 'INPUT_URL must be an absolute URL' log.txt; then
        echo "Valid IPv6 URL failed URL validation: ${url}"
        exit 1
    fi
    grep -F 'Unexpected factbase processing' log.txt
done
