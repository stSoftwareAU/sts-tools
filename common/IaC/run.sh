#!/bin/bash
#
# WARNING: Automatically copied from sts-tools
#
set -e
BASE_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cd "${BASE_DIR}"

args=()
MODE=""
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
  -m | --mode)
    shift # past argument
    MODE="$1"
    ;;
  -r | --require)
    shift # past argument
    REQUIRED_VERSION="$1"
    # shift
    ;;
  *)
    args+=("${1}")
    ;;
  esac

  shift
done

if [[ -z "${MODE}" ]]; then
  echo "MODE not defined"
  exit 1
fi

if [[ -z "${WHO}" ]]; then
  WHO=$(whoami)
fi

. ./init.sh

checkArea=$(echo "${AREA}" | tr '[:upper:]' '[:lower:]')
if [[ ! ${ACCOUNT_ALIAS} =~ ^.*${checkArea}$ ]]; then
  if [[ ${ACCOUNT_ALIAS} =~ ^.*-pipeline$ ]] && [[ ${checkArea} == 'develop' ]]; then
    echo "${ACCOUNT_ALIAS} expected to be in ${AREA}"
  else
    if [[ ! "${MODE}" =~ (validate) ]]; then
      echo "Wrong AREA (${AREA}) for account (${ACCOUNT_ALIAS}) for mode (${MODE})"
      exit 1
    fi
  fi
fi

tf_dir=$(mktemp -d -t tf_XXXXXXXXXX)
tmpConfig=$(mktemp -d -t config_XXXXXXXXXX)

s3_tf="${S3_BUCKET}/${DOCKER_REPO}"
mkdir -p "${tf_dir}/store"
aws --profile "${PROFILE}" s3 cp "s3://${s3_tf}/store/terraform.tfstate" "${tf_dir}/store" || true

if [[ ! "${MODE}" =~ (validate) ]]; then
  tmpApps=$(mktemp -t apps_XXXXXXXXXX)
  aws --profile "${PROFILE}" appconfig list-applications >"${tmpApps}"

  APP=$(jq ".Items[]|select( .Name==\"${DOCKER_REPO}\" )" "${tmpApps}")
  rm "${tmpApps}"
  if [[ -n "${APP}" ]]; then
    aws --profile "${PROFILE}" appconfig get-configuration --application "${DOCKER_REPO}" --environment "${AREA,,}" --configuration config --client-id any-id "${tmpConfig}/config.auto.tfvars.json"
  fi
fi

DIGEST=$(docker inspect "${DOCKER_REPO}:latest" | jq -r .[0].Id)

jq ".who=\"${WHO:-Unknown}\" | .digest=\"${DIGEST}\"" <<<"{}" >"${tmpConfig}/build.auto.tfvars.json"

mkdir -p "${tf_dir}/store"
chmod -R ugo+rw "${tf_dir}"

chmod ugo+rxw "${tmpConfig}"
chmod -R ugo+rw "${tmpConfig}"

prefix=".sts-tools#aws_"
find /tmp -name "${prefix}" -exec rm -rvf {} \;
tmpAWS=$(mktemp -d -t "${prefix}XXXXXXXXXX")
AWS_PROFILE=${PROFILE}
export AWS_PROFILE
cp -a .aws/* "${tmpAWS}/"
docker run \
  --dns 8.8.8.8 \
  --rm \
  --env REQUIRED_VERSION="${REQUIRED_VERSION}" \
  --env WHO="${WHO}" \
  --env AWS_ACCESS_KEY_ID \
  --env AWS_SECRET_ACCESS_KEY \
  --env AWS_SESSION_TOKEN \
  --env AWS_DEFAULT_REGION \
  --env AWS_PROFILE \
  --volume "${tmpAWS}:/home/IaC/.aws" \
  --volume "${tf_dir}/store:/home/IaC/store" \
  --volume "${tmpConfig}:/home/IaC/.config" \
  "${DOCKER_REPO}:latest" \
  "${MODE}" "${args[@]}"

rm -rf "${tmpAWS}"
rm -rf "${tmpConfig}"

if [[ -s ${tf_dir}/store/tf.plan ]]; then 
  TS=$(date "+%Y-%m-%d_%H-%M-%S")
  targetFile="${tf_dir}/tf_${TS}.plan"
  mv "${tf_dir}/store/tf.plan" "${targetFile}"
  aws --profile "${PROFILE}" s3 cp "${targetFile}" "s3://${s3_tf}/plans/"
fi 

aws --profile "${PROFILE}" s3 cp "${tf_dir}/store" "s3://${s3_tf}/store" --recursive

rm -rf "${tf_dir}"
