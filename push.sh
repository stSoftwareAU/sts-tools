#!/bin/bash
#
# WARNING: Automatically copied from sts-tools
#
# Turn on errors.
set -ex
# BASE_DIR is picked up from the location of this script.
BASE_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cd "${BASE_DIR}"

# GIT_COMMIT is an environment variable that
# gets set automatically by Jenkins when it
# performs the build.
if [[ -z "${GIT_COMMIT}" ]]; then
  echo "Must specify GIT_COMMIT"
  exit 1
fi

. ./init.sh
env
ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
AREA=$(echo "${AREA}" | tr '[:upper:]' '[:lower:]')
aws --profile "${PROFILE}" ecr get-login-password | docker login --username AWS --password-stdin "${ECR}"

aws --profile "${PROFILE}" ecr describe-repositories --repository-names "temp-${AREA}/${DOCKER_REPO}" ||
  aws --profile "${PROFILE}" ecr create-repository --image-scanning-configuration scanOnPush=true --repository-name "temp-${AREA}/${DOCKER_REPO}"

docker tag "${DOCKER_REPO}:latest" "${ECR}/temp-${AREA}/${DOCKER_REPO}:git_${GIT_COMMIT}"

# List the docker image that will be pushed.
docker images --digests | grep "${DOCKER_REPO}"

docker push --quiet "${ECR}/temp-${AREA}/${DOCKER_REPO}:git_${GIT_COMMIT}"
