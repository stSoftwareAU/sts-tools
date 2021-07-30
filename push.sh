#!/bin/bash
#
# WARNING: Automatically copied from dga-tools
#
set -e
BASE_DIR="$( cd -P "$( dirname "$BASH_SOURCE" )" && pwd -P )"
cd "${BASE_DIR}"

if [[ -z "${GIT_COMMIT}" ]]; then
  echo "Must specify GIT_COMMIT"
  exit 1
fi

. ./init.sh

ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR}

aws ecr describe-repositories --repository-names temp-${AREA,,}/${DOCKER_REPO} || \
    aws ecr create-repository --image-scanning-configuration scanOnPush=true --repository-name temp-${AREA,,}/${DOCKER_REPO}

docker tag ${DOCKER_REPO}:latest ${ECR}/temp-${AREA,,}/${DOCKER_REPO}:${GIT_COMMIT}
docker push ${ECR}/temp-${AREA,,}/${DOCKER_REPO}:${GIT_COMMIT}

docker push ${ECR}/temp-${AREA,,}/${DOCKER_REPO}:${GIT_COMMIT}
