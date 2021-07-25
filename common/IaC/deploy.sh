#!/bin/bash
#
# WARNING: Automatically copied from dga-tools
#
set -e
BASE_DIR="$( cd -P "$( dirname "$BASH_SOURCE" )" && pwd -P )"
cd "${BASE_DIR}"

if [[ "${ACCOUNT_ALIAS}" =~ ^.*pipeline$ ]]; then
  if [[ "${AREA,,}" != "production" ]]; then
    echo "Wrong AREA (${AREA}) for account (${ACCOUNT_ALIAS})"
    exit 1
  fi
fi

./build.sh

./run.sh
