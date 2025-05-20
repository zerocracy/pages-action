#!/bin/bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 Zerocracy
# SPDX-License-Identifier: MIT

testPublishesEmptyFactbase() {
  tmp=target/shunit2/publishes-empty-factbase
  mkdir -p "${tmp}"
  GITHUB_WORKSPACE=${tmp}
  export GITHUB_WORKSPACE
  INPUT_VERBOSE=true
  export INPUT_VERBOSE
  INPUT_OUTPUT=output
  export INPUT_OUTPUT
  INPUT_FACTBASE=test.fb
  export INPUT_FACTBASE
  INPUT_COLUMNS=details
  export INPUT_COLUMNS
  bundle exec judges eval "${tmp}/test.fb" "\$fb.insert" > /dev/null
  ./entry.sh >"${tmp}/log.txt" 2>&1
  assertTrue 'YAML file is absent' "[ -e '${tmp}/output/test.yaml' ]"
  assertTrue 'XML file is absent' "[ -e '${tmp}/output/test.xml' ]"
  assertTrue 'JSON file is absent' "[ -e '${tmp}/output/test.json' ]"
  assertTrue 'HTML file is absent' "[ -e '${tmp}/output/test.html' ]"
  assertTrue 'HTML vitals file is absent' "[ -e '${tmp}/output/test-vitals.html' ]"
}

testPassesGithubToken() {
  tmp=target/shunit2/passes-github-token
  mkdir -p "${tmp}"
  GITHUB_WORKSPACE=${tmp}
  export GITHUB_WORKSPACE
  INPUT_VERBOSE=true
  export INPUT_VERBOSE
  INPUT_OUTPUT=output
  export INPUT_OUTPUT
  INPUT_FACTBASE=test.fb
  export INPUT_FACTBASE
  INPUT_GITHUB_TOKEN=THETOKEN
  export INPUT_GITHUB_TOKEN
  bundle exec judges eval "${tmp}/test.fb" "\$fb.insert" > /dev/null
  ./entry.sh >"${tmp}/log.txt" 2>&1
  assertTrue "grep github_token=THETOKEN '${tmp}/log.txt'"
}
