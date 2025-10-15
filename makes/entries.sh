#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

base=$(realpath "$(dirname "$0")/..")

mkdir -p "${base}/target/entries-logs"
while IFS= read -r sh; do
    mkdir -p "${base}/target/${sh}"
    if /bin/bash -c "cd \"target/${sh}\" && exec \"${base}/entries/${sh}\" \"${base}\" > \"${base}/target/entries-logs/${sh}.txt\" 2>&1"; then
        echo "👍🏻 ${sh} passed"
    else
        log=$(cat "${base}/target/entries-logs/${sh}.txt")
        if [ -z "${log}" ]; then
            echo "❌ ${sh} failed, the log is empty"
        else
            echo "❌ ${sh} failed, here is the log:"
            echo "${log}"
        fi
        exit 1
    fi
done < <( find "${base}/entries" -name '*.sh' -exec basename {} \; )
