#!/bin/bash
#
# WARNING: Automatically copied from dga-tools
#
set -e
BASE_DIR="$( cd -P "$( dirname "$BASH_SOURCE" )" && pwd -P )"
cd "${BASE_DIR}"

. ./init.sh

if [[ -z "${DOCKER_ACCOUNT_ID}" ]]; then
  DOCKER_ACCOUNT_ID="${ACCOUNT_ID}"
fi

ECR="${DOCKER_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR}

if [[ ! -z "${GIT_COMMIT}" ]]; then
  DOCKER_TAG="${GIT_COMMIT}"
    
  docker pull --quiet ${ECR}/temp-${AREA,,}/${DOCKER_REPO}:${GIT_COMMIT}
  docker tag ${ECR}/temp-${AREA,,}/${DOCKER_REPO}:${GIT_COMMIT} ${DOCKER_REPO}:latest
else
  DOCKER_URI="${ECR}/${DOCKER_REPO}"
  docker pull --quiet ${ECR}/${AREA,,}/${DOCKER_REPO}:lastest
  docker tag ${ECR}/${AREA,,}/${DOCKER_REPO}:lastest ${DOCKER_REPO}:latest
fi