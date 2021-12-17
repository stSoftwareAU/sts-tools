#!/bin/bash
#
# WARNING: Automatically copied from sts-tools
#
set -e
BASE_DIR="$(cd -P "$(dirname "$BASH_SOURCE")" && pwd -P)"
cd "${BASE_DIR}"

. ./init.sh

if [[ ! ${ACCOUNT_ALIAS} =~ ^.*"${AREA,,}"$ ]]; then
  echo "Wrong AREA (${AREA}) for account (${ACCOUNT_ALIAS})"
  exit 1
fi

ws_dir=$(mktemp -d -t ws_XXXXXXXXXX)
cp -a ${WORKSPACE}/* ${ws_dir}/

cd ${ws_dir}

tf_dir=$(mktemp -d -t tf_XXXXXXXXXX)
tmpConfig=$(mktemp -d -t config_XXXXXXXXXX)

s3_tf="${S3_BUCKET}/${DOCKER_REPO}"

aws s3 cp s3://${s3_tf} ${tf_dir} --recursive

tmpApps=$(mktemp -t apps_XXXXXXXXXX)
aws appconfig list-applications >${tmpApps}

APP=$(jq ".Items[]|select( .Name==\"${DOCKER_REPO}\" )" ${tmpApps})
rm ${tmpApps}
if [[ ! -z "${APP}" ]]; then
  aws appconfig get-configuration --application ${DOCKER_REPO} --environment ${AREA,,} --configuration config --client-id any-id ${tmpConfig}/config.auto.tfvars.json
fi

mkdir -p "${tf_dir}/store"
chmod -R ugo+rw "${tf_dir}"

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
  import $1 $2

aws s3 cp ${tf_dir}/store s3://${s3_tf}/store --recursive

rm -rf ${tf_dir}
rm -rf ${ws_dir}
