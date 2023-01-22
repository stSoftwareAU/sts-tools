#!/bin/bash
#
# WARNING: Automatically copied from sts-tools.
#
set -e
BASE_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cd "${BASE_DIR}"

export TOOLS_VERSION="3.8.5"

function compareVersion() {
  if [[ $1 == "$2" ]]; then
    RESULT=0
    return
  fi
  local IFS=.
  local i ver1=("$1") ver2=("$2")
  # fill empty fields in ver1 with zeros
  for ((i = ${#ver1[@]}; i < ${#ver2[@]}; i++)); do
    ver1[i]=0
  done
  for ((i = 0; i < ${#ver1[@]}; i++)); do
    if [[ -z ${ver2[i]} ]]; then
      # fill empty fields in ver2 with zeros
      ver2[i]=0
    fi
    if ((10#${ver1[i]} > 10#${ver2[i]})); then
      RESULT=1
      return
    fi
    if ((10#${ver1[i]} < 10#${ver2[i]})); then
      RESULT=-1
      return
    fi
  done

  RESULT=0
  return
}

function checkVersion() {

  compareVersion "${REQUIRED_VERSION:-${TOOLS_VERSION}}" ${TOOLS_VERSION}

  if [[ ${RESULT} -gt 0 ]]; then
    echo "FAIL: Required VERSION ${REQUIRED_VERSION}, was ${TOOLS_VERSION}"
    exit 1
  fi
}

checkVersion

if [[ "${INITIALIZED}" == "YES" ]]; then
  return
fi

if [[ -z "${WORKSPACE}" ]]; then
  WORKSPACE="${BASE_DIR}"
fi

export WORKSPACE

ENV_FILE="${WORKSPACE}/.env" # Default environment used by docker-compose.

if [[ -f ${ENV_FILE} ]]; then
  source ${ENV_FILE}
  export $(grep -v "#" ${ENV_FILE} | cut -d= -f1)
fi

if [[ -z "${ACCOUNT_ID}" ]]; then
  if [[ -n "${PROFILE}" ]]; then
    tmpIdentity=$(mktemp /tmp/identity_XXXXXXXX)
    aws --profile "${PROFILE}" sts get-caller-identity >"${tmpIdentity}"
    ACCOUNT_ID=$(jq -r .Account "${tmpIdentity}")

    REGION=$(aws --profile "${PROFILE}" configure get region) || true
  else

    tmpIdentity=$(mktemp /tmp/identity_XXXXXXXX)

    curl -s http://169.254.169.254/latest/dynamic/instance-identity/document >"${tmpIdentity}" || true

    if [[ -s ${tmpIdentity} ]]; then
      ACCOUNT_ID=$(jq -r .accountId "${tmpIdentity}")
      REGION=$(jq -r .region "${tmpIdentity}")
    fi
  fi
fi

if [[ -z "${REGION}" ]]; then
  REGION="${AWS_DEFAULT_REGION}"
fi

if [[ -z "${GIT_REPO}" ]]; then
  cd "${WORKSPACE}"
  GIT_REPO=$(basename -s .git $(git config --get remote.origin.url))
  cd "${BASE_DIR}"
fi

if [[ -z "${DEPARTMENT}" ]]; then
  DEPARTMENT=$(echo "${GIT_REPO^^}" | cut -d '-' -f 1)
fi

if [[ -z "${PACKAGE}" ]]; then
  let offset=${#DEPARTMENT}+1
  PACKAGE="${GIT_REPO:${offset}}"
fi
export PACKAGE

if [[ -z "${DEPARTMENT}" ]] || [[ -z "${ACCOUNT_ID}" ]] || [[ -z "${REGION}" ]]; then
  echo "Must specify the follow environment variables DEPARTMENT(${DEPARTMENT}), ACCOUNT_ID(${ACCOUNT_ID}) and REGION(${REGION})"
  exit 1
fi

if [[ -z "${AREA}" ]]; then
  # If a PR then use CHANGE_BRANCH
  if [[ -n "${CHANGE_BRANCH}" ]]; then
    AREA="${CHANGE_BRANCH}"
  elif [[ -n "${BRANCH_NAME}" ]]; then
    AREA="${BRANCH_NAME}"
  else
    cd "${WORKSPACE}"
    tmpAREA=$(git branch --show-current)
    cd "${BASE_DIR}"

    AREA="${tmpAREA}"
  fi
fi

tmpAliases=$(mktemp /tmp/aliases_XXXXXXXX)

aws --profile "${PROFILE}" iam list-account-aliases >"${tmpAliases}"

ACCOUNT_ALIAS=$(jq -r .AccountAliases[0] "${tmpAliases}" | tr '[:upper:]' '[:lower]')
rm "${tmpAliases}"
checkDeparment=$(echo "${DEPARTMENT}" | tr '[:upper:]' '[:lower:]')
if [[ ! "${ACCOUNT_ALIAS}" =~ ${checkDeparment}.* ]]; then
  echo "Wrong account (${ACCOUNT_ALIAS}) for department (${DEPARTMENT})"
  exit 1
fi

if [[ ! ${ACCOUNT_ALIAS} =~ ^.*-pipeline$ ]]; then
  checkArea=$(echo "${AREA}" | tr '[:upper:]' '[:lower:]')
  if [[ ! ${ACCOUNT_ALIAS} =~ ^.*${checkArea}$ ]]; then
    echo "Wrong AREA (${AREA}) for account (${ACCOUNT_ALIAS})"
    exit 1
  fi
fi

export ACCOUNT_ALIAS
export AREA

echo "Initialize DEPARTMENT(${DEPARTMENT}), ACCOUNT(${ACCOUNT_ALIAS}#${ACCOUNT_ID}), REGION(${REGION}) and AREA(${AREA}) for PACKAGE(${PACKAGE}) v${TOOLS_VERSION}"

export DEPARTMENT
export ACCOUNT_ID
export REGION="${REGION}"
export AWS_DEFAULT_REGION="${REGION}"

if [[ -z "${DOCKER_REPO}" ]]; then
  DOCKER_REPO=$(echo "${GIT_REPO}" | tr '[:upper:]' '[:lower:]')
fi

export DOCKER_REPO

if [[ -n "${DOCKER_ACCOUNT_ID}" ]]; then
  export DOCKER_ACCOUNT_ID
fi

if [[ -z "${ROLE}" ]]; then
  if [[ -n "${PROFILE}" ]]; then
    ROLE=$(aws --profile "${PROFILE}" sts get-caller-identity | jq -r .Arn | cut -d '/' -f 2)
  fi
fi

if [[ -n "${ROLE}" ]]; then
  ASSUME_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE}"

  tmpCredentials=$(mktemp /tmp/credentials_XXXXXXXX)
  aws sts assume-role --role-arn "${ASSUME_ROLE_ARN}" --role-session-name "Deploy_${REPO:${PACKAGE}}" >"${tmpCredentials}"

  AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' "${tmpCredentials}")
  export AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' "${tmpCredentials}")
  export AWS_SECRET_ACCESS_KEY
  AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' "${tmpCredentials}")
  export AWS_SESSION_TOKEN
  
  rm "${tmpCredentials}"
else
  export PROFILE
fi

REAL_AREA=$(echo "${ACCOUNT_ALIAS}" | cut -d '-' -f 2)
S3_BUCKET=$(echo "${DEPARTMENT}-terraform-${REAL_AREA}-${REGION}" | tr "[:upper:]" "[:lower:]")
export S3_BUCKET
LIST_BUCKETS=$(aws --profile "${PROFILE}" s3api list-buckets)

CreationDate=$(jq ".Buckets[]|select(.Name==\"${S3_BUCKET}\").CreationDate" <<<"$LIST_BUCKETS")
if [[ -z "${CreationDate}" ]]; then
  if [[ -s /home/tools/create-bucket.sh ]]; then
    /home/tools/create-bucket.sh
  else
    echo "No bucket ${S3_BUCKET}"
    exit 1
  fi
fi
export INITIALIZED="YES"
