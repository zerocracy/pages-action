#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

img=$1

test -e target/fb/simple.fb

docker run --rm \
    "--user=$(id -u):$(id -g)" \
    -v "$(realpath "$(pwd)")/target/fb/:/work" \
    -e GITHUB_WORKSPACE=/work \
    -e INPUT_FACTBASE=simple.fb \
    -e INPUT_VERBOSE=true \
    -e INPUT_OUTPUT=pages \
    -e INPUT_COLUMNS=what,when,who \
    -e INPUT_HIDDEN=_id \
    "${img}"
