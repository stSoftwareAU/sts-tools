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

if [[ ! -z "${COMMIT_ID}" ]]; then
  DOCKER_TAG="${COMMIT_ID}"

  docker pull --quiet ${ECR}/temp-${AREA,,}/${DOCKER_REPO}:${COMMIT_ID}
  docker tag ${ECR}/temp-${AREA,,}/${DOCKER_REPO}:${COMMIT_ID} ${DOCKER_REPO}:latest
else
  DOCKER_URI="${ECR}/${DOCKER_REPO}"
  docker pull --quiet ${ECR}/${AREA,,}/${DOCKER_REPO}:latest
  docker tag ${ECR}/${AREA,,}/${DOCKER_REPO}:latest ${DOCKER_REPO}:latest
fi
