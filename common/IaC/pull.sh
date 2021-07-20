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

if [[ -z "${DOCKER_TAG}" ]]; then
  if [[ ! -z "${GIT_COMMIT}" ]]; then
    DOCKER_TAG="${GIT_COMMIT}"
  elif [[ -z "${AREA}" ]]; then
    echo "No DOCKER_TAG, GIT_COMMIT or AREA"
    exit 1
  else
    DOCKER_TAG="${AREA}"
  fi
fi

DOCKER_URI="${ECR}/${DOCKER_REPO}"
docker pull ${DOCKER_URI}:${DOCKER_TAG}
docker tag ${DOCKER_URI}:${DOCKER_TAG} ${DOCKER_REPO}:latest
