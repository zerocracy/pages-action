#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

VERSION=0.0.0

echo "The 'pages-action' ${VERSION} is running"

if [ "${INPUT_VERBOSE}" == 'true' ]; then
    set -x
fi

if [ -z "$1" ]; then
    SELF=$(dirname "$0")
else
    SELF=$1
fi

if [ -z "${JUDGES}" ]; then
    BUNDLE_GEMFILE="${SELF}/Gemfile"
    export BUNDLE_GEMFILE
    JUDGES='bundle exec judges'
fi
echo "The 'judges' gem will be started as: '${JUDGES}'"

${JUDGES} --version

if [ -z "${GITHUB_WORKSPACE}" ]; then
    echo 'Probably you are running this script not from GitHub Actions.'
    echo "Use 'make' instead: it configures all environment variables correctly."
    exit 1
fi
cd "${GITHUB_WORKSPACE}"
echo "The workspace directory is: $(pwd)"

declare -a gopts=()
if [ -n "${INPUT_VERBOSE}" ]; then
    gopts+=("--verbose")
    export GLI_DEBUG=true
else
    echo "Since 'verbose' is not set to 'true', you won't see detailed logs"
fi

if [ -z "${INPUT_OUTPUT}" ]; then
    echo "It is mandatory to specify the 'output' argument, which is the name"
    echo "of a directory where YAML, JSON, and other human-readable files"
    echo "will be generated by the plugin"
    exit 1
fi
mkdir -p "${INPUT_OUTPUT}"
echo "The output directory is: ${INPUT_OUTPUT}"

name=$(basename "${INPUT_FACTBASE}")
name="${name%.*}"
echo "The factbase name is: '${name}'"

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
github_token_found=false
for opt in "${options[@]}"; do
    if [[ "${opt}" == "--option=github_token="* ]]; then
        github_token_found=true
        break
    fi
done
if [ "${github_token_found}" == "true" ]; then
    echo "The 'github_token' option is set, using it"
fi
if [ "${github_token_found}" == "false" ]; then
    if [ -z "$(printenv "INPUT_GITHUB-TOKEN")" ]; then
        echo "The 'github-token' plugin parameter is not set (\$INPUT_GITHUB-TOKEN is empty)"
    else
        echo "The 'github-token' plugin parameter is set, using it"
        options+=("--option=github_token=$(printenv "INPUT_GITHUB-TOKEN")");
        github_token_found=true
    fi
fi

${JUDGES} "${gopts[@]}" update \
    --shuffle= \
    --no-log \
    --summary=off \
    --max-cycles 1 \
    "${options[@]}" \
    "${SELF}/judges/" "${INPUT_FACTBASE}"
${JUDGES} "${gopts[@]}" print \
    --format xml \
    "${INPUT_FACTBASE}" \
    "${INPUT_OUTPUT}/${name}.rich.xml"

if [ -z "${INPUT_TODAY}" ]; then
    INPUT_TODAY=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
else
    echo "The 'today' is set to: '${INPUT_TODAY}'"
fi

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
echo "HTML generated at: ${html}"
rm "${INPUT_OUTPUT}/${name}.rich.xml"
