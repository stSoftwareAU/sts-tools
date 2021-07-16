#!/bin/bash
#
# WARNING: Automatically copied from dga-template
#
set -e
BASE_DIR="$( cd -P "$( dirname "$BASH_SOURCE" )" && pwd -P )"
cd "${BASE_DIR}"

TOOLS_WORKSPACE="${WORKSPACE}"
IMPORT_RESOURCE=""
IMPORT_ID=""
MODE="repl"
me=`basename "$0"`
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -w|--workspace)
      shift # past argument
      TOOLS_WORKSPACE="$1"
      shift
      ;;
    -r|--resource)
      shift # past argument
      IMPORT_RESOURCE="$1"
      shift
      ;;
    -i|--id)
      shift # past argument
      IMPORT_ID="$1"
      shift
      ;;      
    -m|--mode)
      shift # past argument
      MODE="$1"
      shift
      ;;
    *)    # unknown option
      echo "Usage ${me} ([-w|--workspace] dir) ([-m|--mode] mode)"
      echo "Unknown option ${key}"
      exit 1
      ;;
  esac
done

if [[ -z "${TOOLS_WORKSPACE}" ]]; then 
    echo "workspace not defined"
    exit 1
fi

if [[ ! -d "${TOOLS_WORKSPACE}" ]]; then
    echo "Not a directory ${TOOLS_WORKSPACE}"
    exit 1
fi

# . ./init.sh
# TOOLS_REPO="dga-tools"

docker run \
    --dns 8.8.8.8 \
    --rm \
    --interactive \
    --tty \
    --env AWS_ACCESS_KEY_ID \
    --env AWS_SECRET_ACCESS_KEY \
    --env AWS_SESSION_TOKEN \
    --env AWS_DEFAULT_REGION \
    --env ACCOUNT_ID \
    --env GIT_COMMIT \
    --env DEPARTMENT \
    --env AREA \
    --env ROLE \
    --env PROFILE \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume ${TOOLS_WORKSPACE}:/home/workspace \
    --volume /tmp:/tmp \
    ${DOCKER_REPO}:latest \
    ${MODE} ${IMPORT_RESOURCE} ${IMPORT_ID}