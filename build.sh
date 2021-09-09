#!/bin/bash
set -e
BASE_DIR="$( cd -P "$( dirname "$BASH_SOURCE" )" && pwd -P )"
cd "${BASE_DIR}"
TOOLS_REPO="dga-tools"

docker build --tag ${TOOLS_REPO}:latest .

# List out the digest for the built image so that we can manually confirm 
# what is checked in is what is built and then deployed.
docker images --digests |grep ${DOCKER_REPO}
