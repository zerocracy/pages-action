#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

set -ex -o pipefail

VERSION=0.0.46

if [ -z "$1" ]; then
    SELF=$(pwd)
else
    SELF=$1
fi

if [ -z "${JUDGES}" ]; then
    opts=( bundle exec "--gemfile=${SELF}/Gemfile" judges )
    JUDGES="${opts[*]}"
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

for f in yaml xml json html; do
    ${JUDGES} "${gopts[@]}" print \
        --format "${f}" \
        --columns "${INPUT_COLUMNS}" \
        --hidden "${INPUT_HIDDEN}" \
        "${INPUT_FACTBASE}" \
        "${INPUT_OUTPUT}/${name}.${f}"
done

declare -a options=()
while IFS= read -r o; do
    v=$(echo "${o}" | xargs)
    if [ "${v}" = "" ]; then
        continue
    fi
    options+=("--option=${v}")
done <<< "${INPUT_OPTIONS}"

${JUDGES} "${gopts[@]}" update \
    --no-log \
    --no-summary \
    --max-cycles 1 \
    "${options[@]}" \
    "${SELF}/judges/" "${INPUT_FACTBASE}"
${JUDGES} "${gopts[@]}" print \
    --format xml \
    "${INPUT_FACTBASE}" \
    "${INPUT_OUTPUT}/${name}.rich.xml"

# This is the day of "today", when we want to see the situation in the project
if [ -z "${INPUT_TODAY}" ]; then
    INPUT_TODAY=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
fi

# Build a summary HTML.
html=${INPUT_OUTPUT}/${name}-vitals.html
java -jar "${SELF}/target/saxon.jar" \
    "-s:${INPUT_OUTPUT}/${name}.rich.xml" \
    "-xsl:${SELF}/target/xsl/vitals.xsl" \
    "-o:${html}" \
    "today=${INPUT_TODAY}" \
    "version=${VERSION}" \
    "fbe=$(cd "${SELF}" && bundle info fbe | head -1 | cut -f5 -d' ' | sed s/[\(\)]//g)" \
    "name=${name}" \
    "logo=${INPUT_LOGO}" \
    "css=$(cat "${SELF}/target/css/main.css")" \
    "js=$(cat "${SELF}/target/js/main.js")"
html-minifier "${html}" --config-file "${SELF}/html-minifier-config.json" -o "${html}"
echo "HTML generated at ${html}"
rm "${INPUT_OUTPUT}/${name}.rich.xml"
