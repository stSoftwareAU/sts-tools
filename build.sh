#!/bin/bash
set -e
BASE_DIR="$(cd -P "$(dirname "$BASH_SOURCE")" && pwd -P)"
cd "${BASE_DIR}"
TOOLS_REPO="sts-tools"

docker build --tag ${TOOLS_REPO}:latest .
