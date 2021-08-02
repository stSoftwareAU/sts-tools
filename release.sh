#!/bin/bash
set -e
BASE_DIR="$( cd -P "$( dirname "$BASH_SOURCE" )" && pwd -P )"
cd "${BASE_DIR}"

if [[ -z "${GIT_COMMIT}" ]]; then
  echo "Must specify GIT_COMMIT"
  exit 1
fi

. ./init.sh

if [[ ! ${ACCOUNT_ALIAS} =~ ^.*"${AREA,,}"$ ]]; then
  echo "Wrong AREA (${AREA}) for account (${ACCOUNT_ALIAS})"
  exit 1
fi

EXT=`date "+%Y%m%d%H%M%S"`

ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR}

aws ecr describe-repositories --repository-names "${AREA,,}/${DOCKER_REPO}" || \
    aws ecr create-repository --image-scanning-configuration scanOnPush=true --repository-name "${AREA,,}/${DOCKER_REPO}"

docker pull --quiet "${ECR}/temp-${AREA,,}/${DOCKER_REPO}:${GIT_COMMIT}"

docker tag "${ECR}/temp-${AREA,,}/${DOCKER_REPO}:${GIT_COMMIT}" \
           "${ECR}/${AREA,,}/${DOCKER_REPO}:released_${EXT}"

docker push --quiet "${ECR}/${AREA,,}/${DOCKER_REPO}:released_${EXT}"

docker tag "${ECR}/${AREA,,}/${DOCKER_REPO}:released_${EXT}" \
           "${ECR}/${AREA,,}/${DOCKER_REPO}:latest"

docker push --quiet "${ECR}/${AREA,,}/${DOCKER_REPO}:latest"
