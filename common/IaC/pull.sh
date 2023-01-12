#!/bin/bash
#
# WARNING: Automatically copied from sts-tools
#
set -e
BASE_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cd "${BASE_DIR}"

. ./init.sh

if [[ -z "${DOCKER_ACCOUNT_ID}" ]]; then
  DOCKER_ACCOUNT_ID="${ACCOUNT_ID}"
fi

ECR="${DOCKER_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

aws --profile "${PROFILE}" ecr get-login-password | docker login --username AWS --password-stdin "${ECR}"

if [[ -n "${GIT_COMMIT}" ]]; then
  docker pull --quiet "${ECR}/temp-${AREA,,}/${DOCKER_REPO}:git_${GIT_COMMIT}"
  docker tag "${ECR}/temp-${AREA,,}/${DOCKER_REPO}:git_${GIT_COMMIT}" "${DOCKER_REPO}:latest"
else
  echo "No COMMIT_ID using latest"
  docker pull --quiet "${ECR}/${AREA,,}/${DOCKER_REPO}:latest"
  docker tag "${ECR}/${AREA,,}/${DOCKER_REPO}:latest" "${DOCKER_REPO}:latest"
fi

# List the docker image that was actually pulled.
docker images --digests | grep "${DOCKER_REPO}"
