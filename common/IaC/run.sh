#!/bin/bash
#
# WARNING: Automatically copied from dga-tools
#
set -e
BASE_DIR="$( cd -P "$( dirname "$BASH_SOURCE" )" && pwd -P )"
cd "${BASE_DIR}"

. ./init.sh

tf_dir=$(mktemp -d -t tf_XXXXXXXXXX)
tmpConfig=$(mktemp -d -t config_XXXXXXXXXX)

s3_tf="${S3_BUCKET}/${DOCKER_REPO}"

aws s3 cp s3://${s3_tf} ${tf_dir} --recursive

aws appconfig get-configuration --application ${DOCKER_REPO} --environment ${AREA} --configuration config --client-id any-id ${tmpConfig}/.config.auto.tfvars.json ||true

mkdir -p ${tf_dir}/store
chmod -R ugo+rw ${tf_dir}

chmod ugo+rxw "${tmpConfig}"
chmod -R ugo+rw "${tmpConfig}"

docker run \
    --dns 8.8.8.8 \
    --rm \
    --env AWS_ACCESS_KEY_ID \
    --env AWS_SECRET_ACCESS_KEY \
    --env AWS_SESSION_TOKEN \
    --env AWS_DEFAULT_REGION \
    --volume ${tf_dir}/store:/home/IaC/store \
    --volume ${tmpConfig}:/home/IaC/.config \
    ${DOCKER_REPO}:latest \
    apply

rm -rf ${tmpConfig}

aws s3 cp ${tf_dir}/store s3://${s3_tf}/store --recursive

rm -rf ${tf_dir}