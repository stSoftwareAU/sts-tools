#!/bin/bash
set -e
BASE_DIR="$(cd -P "$(dirname "$BASH_SOURCE")" && pwd -P)"
cd "${BASE_DIR}"

bash -x ../common/IaC/cve-scan.sh --scan $(pwd)/cve-scan.json --allow $(pwd)/cve-allow.json 
