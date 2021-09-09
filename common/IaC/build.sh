#!/bin/bash
#
# WARNING: Automatically copied from dga-tools
#
set -e
BASE_DIR="$(cd -P "$(dirname "$BASH_SOURCE")" && pwd -P)"
cd "${BASE_DIR}"

. ./init.sh

ws_dir=$(mktemp -d -t ws_XXXXXXXXXX)
cp -a ${WORKSPACE}/* ${ws_dir}/
cp Dockerfile ${ws_dir}/
cp entrypoint.sh ${ws_dir}/
cd ${ws_dir}

tf_dir=$(mktemp -d -t tf_XXXXXXXXXX)

s3_tf="${S3_BUCKET}/${DOCKER_REPO}"

aws s3 cp s3://${s3_tf} ${tf_dir} --recursive
chmod -R ugo+rw ${tf_dir}

jq ".area=\"${AREA}\" | .region=\"${REGION}\" | .department=\"${DEPARTMENT}\"| .package=\"${PACKAGE}\"" <<<"{}" >IaC/.auto.tfvars.json

if [[ -f "${ws_dir}/pre-build.sh" ]]; then
  ${ws_dir}/pre-build.sh
fi

docker build --quiet --tag ${DOCKER_REPO}:latest .

if [[ -f "${ws_dir}/post-build.sh" ]]; then
  ${ws_dir}/post-build.sh
fi

## Clean up.
rm -r ${tf_dir}
rm -f IaC/.auto.tfvars.json

cd "${BASE_DIR}"
rm -r ${ws_dir}
