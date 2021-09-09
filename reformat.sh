#!/bin/bash
set -e
BASE_DIR="$(cd -P "$(dirname "$BASH_SOURCE")" && pwd -P)"
cd "${BASE_DIR}"

TOOLS_WORKSPACE="${WORKSPACE}"

me=$(basename "$0")
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
  -w | --workspace)
    shift # past argument
    TOOLS_WORKSPACE="$1"
    # shift
    ;;
  *)
    echo "${key}: Unknown argument"
    exit 5
    ;;
  esac

  shift
done

if [[ -z "${TOOLS_WORKSPACE}" ]]; then
  echo "workspace not defined"
  exit 1
fi

docker run --volume ${TOOLS_WORKSPACE}/IaC:/home/IaC --rm hashicorp/terraform:light -chdir=/home/IaC fmt
