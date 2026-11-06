#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

for scheme in http HTTP hTtP https HTTPS hTtPs; do
    if env "GITHUB_WORKSPACE=${PWD}" 'JUDGES=true' 'LATEST_VERSION=test' \
        "INPUT_URL=${scheme}://example.com/reports" \
        "${SELF}/entry.sh" > log.txt 2>&1; then
        echo 'Expected factbase discovery to fail in an empty workspace'
        exit 1
    fi
    grep -F 'The workspace directory is:' log.txt
    grep -F 'ERROR: No .fb files found in the current directory.' log.txt
done
