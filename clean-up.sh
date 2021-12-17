#!/bin/bash
set -e
BASE_DIR="$(cd -P "$(dirname "$BASH_SOURCE")" && pwd -P)"
cd "${BASE_DIR}"

if [[ -z "${GIT_COMMIT}" ]]; then
  echo "Must specify GIT_COMMIT"
  exit 1
fi

. ./init.sh

ECR="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

aws ecr get-login-password | docker login --username AWS --password-stdin ${ECR}

aws ecr describe-repositories --repository-names "${AREA,,}/${DOCKER_REPO}" ||
  aws ecr create-repository --image-scanning-configuration scanOnPush=true --repository-name "${AREA,,}/${DOCKER_REPO}"

aws ecr batch-delete-image \
  --repository-name "temp-${AREA,,}/${DOCKER_REPO}" \
  --image-ids imageTag="git_${GIT_COMMIT}"

#set +e
#docker rmi `docker images |egrep -v "tools.*latest"|cut -c 45-56`
