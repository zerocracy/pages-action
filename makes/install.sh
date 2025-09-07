#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')

bundle install
if [ "${OS_NAME}" = "darwin" ]; then
    brew install tidy-html5
else
    if ! ( [ -f /proc/self/cgroup ] && grep -q ":" /proc/self/cgroup ); then
        apt-get install -y tidy
    fi
fi
npm --no-color install -g eslint@9.22.0
npm --no-color install -g uglify-js@3.19.3
npm --no-color install -g sass@1.77.2
npm --no-color install -g stylelint@16.15.0 stylelint-config-standard@37.0.0 stylelint-scss@6.11.1
npm --no-color install -g html-minifier@4.0.0
