#!/bin/bash
set -e
BASE_DIR="$(cd -P "$(dirname "$BASH_SOURCE")" && pwd -P)"
cd "${BASE_DIR}"
TOOLS_REPO="sts-tools"

userId=$(id -u)
groupId=$(id -g)
docker build --build-arg USER_ID=${userId} --build-arg GROUP_ID=${groupId} --tag ${TOOLS_REPO}:latest .
