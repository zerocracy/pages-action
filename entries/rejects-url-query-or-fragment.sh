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
