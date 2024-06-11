#!/bin/bash
# MIT License
#
# Copyright (c) 2024 Zerocracy
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set -e
set -o pipefail

VERSION=0.0.9

if [ -z "${JUDGES}" ]; then
    JUDGES=judges
fi

if [ -z "$1" ]; then
    SELF=$(pwd)
else
    SELF=$1
fi

# Convert the factbase to a few human-readable formats
if [ -z "${GITHUB_WORKSPACE}" ]; then
    echo 'Probably you are running this script not from GitHub Actions.'
    echo "Use 'make' instead: it configures all environment variables correctly."
    exit 1
fi
cd "${GITHUB_WORKSPACE}"

declare -a gopts=()
if [ -n "${INPUT_VERBOSE}" ]; then
    gopts+=("--verbose")
    export GLI_DEBUG=true
fi

# Convert the factbase to a few human-readable formats
if [ -z "${INPUT_OUTPUT}" ]; then
    echo "It is mandatory to specify the 'output' argument, which is the name"
    echo "of a directory where YAML, JSON, and other human-readable files"
    echo "are going to be generated by the plugin"
    exit 1
fi
mkdir -p "${INPUT_OUTPUT}"

name=$(basename "${INPUT_FACTBASE}")
name="${name%.*}"

for f in yaml xml json; do
    "${JUDGES}" "${gopts[@]}" print --format "${f}" "${INPUT_FACTBASE}" "${INPUT_OUTPUT}/${name}.${f}"
done

# Build a summary HTML.
css=$(cat "${SELF}/target/css/main.css")
java -jar "${SELF}/target/saxon.jar" \
    "-s:${INPUT_OUTPUT}/${name}.xml" \
    "-xsl:${SELF}/target/xsl/index.xsl" \
    "-o:${INPUT_OUTPUT}/${name}.html" \
    "version=${VERSION}" \
    "name=${name}" \
    "css=${css}"
