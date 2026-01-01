#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

e2=$(cat target/entry.exit)
test "${e2}" = "0"

tree target/fb/

test -e target/fb/pages/simple-vitals.html
test -e target/fb/pages/simple.html
test -e target/fb/pages/simple.xml
test -e target/fb/pages/simple.json
test -e target/fb/pages/simple.yaml
