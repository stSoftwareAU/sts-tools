#!/bin/bash
set -e
BASE_DIR="$(cd -P "$(dirname "$BASH_SOURCE")" && pwd -P)"
cd "${BASE_DIR}"

if [[ -z "${GIT_COMMIT}" ]]; then
  echo "Must specify GIT_COMMIT"
  exit 1
fi

. ./init.sh

TS=$(date "+%Y%m%d%H%M%S%Z")
EXT="git_${GIT_COMMIT}"
UNIQUE_EXT="ts_${TS}-${EXT}"

ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR}

aws ecr describe-repositories --repository-names "${AREA,,}/${DOCKER_REPO}" ||
  aws ecr create-repository --image-scanning-configuration scanOnPush=true --repository-name "${AREA,,}/${DOCKER_REPO}"

docker pull --quiet "${ECR}/temp-${AREA,,}/${DOCKER_REPO}:${EXT}"

docker tag "${ECR}/temp-${AREA,,}/${DOCKER_REPO}:${EXT}" \
  "${ECR}/${AREA,,}/${DOCKER_REPO}:${UNIQUE_EXT}"

docker tag "${ECR}/${AREA,,}/${DOCKER_REPO}:${UNIQUE_EXT}" \
  "${ECR}/${AREA,,}/${DOCKER_REPO}:${EXT}"

docker tag "${ECR}/${AREA,,}/${DOCKER_REPO}:${UNIQUE_EXT}" \
  "${ECR}/${AREA,,}/${DOCKER_REPO}:latest"

# List the docker image that will be released.
docker images --digests | grep ${DOCKER_REPO}

docker push --quiet "${ECR}/${AREA,,}/${DOCKER_REPO}:${UNIQUE_EXT}"
docker push --quiet "${ECR}/${AREA,,}/${DOCKER_REPO}:${EXT}"
docker push --quiet "${ECR}/${AREA,,}/${DOCKER_REPO}:latest"

./clean-up.sh