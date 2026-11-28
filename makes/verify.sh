#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

tree target/fb/

for suffix in -vitals.html -badge.svg .html .xml .json .yaml; do
    test -f "target/fb/pages/simple${suffix}"
done
