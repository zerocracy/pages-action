#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

base=$(realpath "$(dirname "$0")/..")

mkdir -p "${base}/target/entries-logs"
find "${base}/entries" -type f -name '*.sh' -print0 | while IFS= read -r -d '' script; do
    sh=${script#"${base}/entries/"}
    rm -rf "${base}/target/${sh}"
    mkdir -p "${base}/target/${sh}" "$(dirname "${base}/target/entries-logs/${sh}.txt")"
    if (cd "${base}/target/${sh}" && exec "${script}" "${base}") > "${base}/target/entries-logs/${sh}.txt" 2>&1; then
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
done
