#!/bin/bash
#
# WARNING: Automatically copied from dga-tools
#
set -e
BASE_DIR="$( cd -P "$( dirname "$BASH_SOURCE" )" && pwd -P )"
cd "${BASE_DIR}"

docker run --volume ${BASE_DIR}/IaC:/home/IaC --rm hashicorp/terraform:light -chdir=/home/IaC fmt
