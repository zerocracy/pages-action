#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')

bundle config set --local frozen true
bundle install
if [ "${OS_NAME}" = "darwin" ]; then
    brew install tidy-html5
else
    command -v tidy >/dev/null || sudo apt-get install -y tidy
fi
npm --no-color install --no-save @eslint/js@10.0.1
npm --no-color install -g eslint@10.15.0
npm --no-color install -g uglify-js@3.19.3
npm --no-color install -g sass@1.108.2
npm --no-color install -g stylelint@18.0.0 stylelint-config-standard@41.0.0
npm --no-color install -g html-minifier@5.4.1
