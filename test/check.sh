#!/bin/bash
set -e
BASE_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cd "${BASE_DIR}"

../common/IaC/cve-scan.sh --scan "$(pwd)/cve-scan.json" --allow "$(pwd)/cve-allow.json"

set +e
../common/IaC/cve-scan.sh --scan "$(pwd)/fail-scan.json" --allow "$(pwd)/cve-allow.json"
ERROR=$?

if [[ ${ERROR} == 0 ]]; then
    echo "Should have failed"
    exit 1
fi
