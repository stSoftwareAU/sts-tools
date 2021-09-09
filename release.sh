#!/bin/bash
set -e
BASE_DIR="$( cd -P "$( dirname "$BASH_SOURCE" )" && pwd -P )"
cd "${BASE_DIR}"

if [[ -z "${COMMIT_ID}" ]]; then
  echo "Must specify COMMIT_ID"
  exit 1
fi

. ./init.sh

EXT=`date "+%Y%m%d%H%M%S"`

ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR}

aws ecr describe-repositories --repository-names "${AREA,,}/${DOCKER_REPO}" || \
    aws ecr create-repository --image-scanning-configuration scanOnPush=true --repository-name "${AREA,,}/${DOCKER_REPO}"

docker pull --quiet "${ECR}/temp-${AREA,,}/${DOCKER_REPO}:git_${COMMIT_ID}"

docker tag "${ECR}/temp-${AREA,,}/${DOCKER_REPO}:git_${COMMIT_ID}" \
           "${ECR}/${AREA,,}/${DOCKER_REPO}:git_${COMMIT_ID}"

docker tag "${ECR}/${AREA,,}/${DOCKER_REPO}:git_${COMMIT_ID}" \
           "${ECR}/${AREA,,}/${DOCKER_REPO}:released_${EXT}"


docker tag "${ECR}/${AREA,,}/${DOCKER_REPO}:git_${COMMIT_ID}" \
           "${ECR}/${AREA,,}/${DOCKER_REPO}:latest"

# List the docker image that will be released.
docker images --digests |grep ${DOCKER_REPO}

docker push --quiet "${ECR}/${AREA,,}/${DOCKER_REPO}:git_${COMMIT_ID}"
docker push --quiet "${ECR}/${AREA,,}/${DOCKER_REPO}:released_${EXT}"
docker push --quiet "${ECR}/${AREA,,}/${DOCKER_REPO}:latest"

aws ecr batch-delete-image \
     --repository-name "temp-${AREA,,}/${DOCKER_REPO}" \
     --image-ids imageTag="git_${COMMIT_ID}"