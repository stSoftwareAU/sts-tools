#!/bin/bash
set -e
BASE_DIR="$( cd -P "$( dirname "$BASH_SOURCE" )" && pwd -P )"
cd "${BASE_DIR}"

TOOLS_WORKSPACE="${WORKSPACE}"
args=()
MODE=""

me=`basename "$0"`
while [[ $# -gt 0 ]]; do
  key="$1"
  # ((pos+=1))

  case $key in
    -w|--workspace)
      shift # past argument
      TOOLS_WORKSPACE="$1"
      # shift
      ;;
#    -r|--resource)
#      shift # past argument
#      IMPORT_RESOURCE="$1"
#      shift
#      ;;
#    -i|--id)
#      shift # past argument
#      IMPORT_ID="$1"
#      shift
#      ;;      
    -m|--mode)
      shift # past argument
      MODE="$1"
      args+=("--mode")
      args+=("${MODE}")
      # shift
      ;;
    *)
      args+=("${1}")
      ;;
  esac

  shift
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
TOOLS_REPO="dga-tools"

docker run \
    --dns 8.8.8.8 \
    --rm \
    --user $(id -u):$(getent group docker|cut -d ':' -f 3)\
    --interactive \
    --tty \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume ${TOOLS_WORKSPACE}:/home/workspace \
    --volume ${HOME}/.aws:/home/tools/.aws \
    --volume /tmp:/tmp \
    ${TOOLS_REPO}:latest \
    "${args[@]}"
