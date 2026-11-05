#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2024-2026 Zerocracy
# SPDX-License-Identifier: MIT

set -e -o pipefail

SELF=$1

cat > judges-sentinel <<'SENTINEL'
#!/usr/bin/env bash
if [ "$1" = '--version' ]; then
    echo 'judges 0.0.0'
    exit 0
fi
echo 'Reached judges after validation'
exit 77
SENTINEL
chmod +x judges-sentinel
touch test.fb

run_check() {
    local timeout=$1
    local lifetime=$2
    env "GITHUB_WORKSPACE=${PWD}" "JUDGES=${PWD}/judges-sentinel" \
        'LATEST_VERSION=test' 'INPUT_FACTBASE=test.fb' \
        'INPUT_OUTPUT=output' "INPUT_TIMEOUT=${timeout}" \
        "INPUT_LIFETIME=${lifetime}" \
        "${SELF}/entry.sh" > log.txt 2>&1
}

# 10 minutes timeout (600s) and 10 minutes lifetime (600s) must fail
if run_check 10 10; then
    echo 'Expected 10 and 10 to fail'
    exit 1
fi
grep -Fx 'INPUT_LIFETIME (600 seconds) must be at least 10 percent bigger than INPUT_TIMEOUT (600 seconds)' log.txt

# 20 minutes timeout (1200s) and 21 minutes lifetime (1260s) must fail (margin 60s < 120s)
if run_check 20 21; then
    echo 'Expected 20 and 21 to fail'
    exit 1
fi
grep -Fx 'INPUT_LIFETIME (1260 seconds) must be at least 10 percent bigger than INPUT_TIMEOUT (1200 seconds)' log.txt

# 100 minutes timeout (6000s) and 109 minutes lifetime (6540s) must fail (margin 540s < 600s)
if run_check 100 109; then
    echo 'Expected 100 and 109 to fail'
    exit 1
fi
grep -Fx 'INPUT_LIFETIME (6540 seconds) must be at least 10 percent bigger than INPUT_TIMEOUT (6000 seconds)' log.txt

# 10 minutes timeout (600s) and 11 minutes lifetime (660s) passes validation and reaches sentinel
if run_check 10 11; then
    code=0
else
    code=$?
fi
if [ "${code}" -ne 77 ]; then
    echo "Expected sentinel exit code 77, got ${code}"
    cat log.txt
    exit 1
fi
grep -F 'Reached judges after validation' log.txt
