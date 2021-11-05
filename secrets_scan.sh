#!/bin/bash
#
# Make sure AWS secrets aren't checked into the code.
#
# https://aws.amazon.com/blogs/security/a-safer-way-to-distribute-aws-credentials-to-ec2/
#
set -e
BASE_DIR="$(cd -P "$(dirname "$BASH_SOURCE")" && pwd -P)"
cd "${BASE_DIR}"

SCAN_WORKSPACE="${WORKSPACE}"
args=()
MODE=""

me=$(basename "$0")
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
    -w | --workspace)
        shift # past argument
        SCAN_WORKSPACE="$1"
        # shift
        ;;
    *)
        args+=("${1}")
        ;;
    esac

    shift
done

if [[ -z "${SCAN_WORKSPACE}" ]]; then
    echo "workspace not defined"
    exit 1
fi

if [[ ! -d "${SCAN_WORKSPACE}" ]]; then
    echo "Not a directory ${SCAN_WORKSPACE}"
    exit 1
fi

tmpScan=$(mktemp /tmp/scan_XXXXXX.txt)

function cleanUp() {
    cat ${tmpScan}
    rm ${tmpScan}
}

trap 'cleanUp' EXIT

find "${SCAN_WORKSPACE}" -not -path '*/\.*' -not -path '*/*.css' -not -path '*/*.png' -type f -exec grep -HP '=[" ]*(?<![A-Z0-9])[A-Z0-9]{20}(?![A-Z0-9])' {} \; >${tmpScan}

if [[ -s ${tmpScan} ]]; then
    echo "AWS ACCESS KEY IDs must not be checked into GitHub"
    exit 1
fi

find "${SCAN_WORKSPACE}" -type f -not -path '*/\.*' -exec grep -HP '[kK][Ee][Yy][" ]*=[" ]*(?<![A-Za-z0-9+=])[A-Za-z0-9+=]{40}(?![A-Za-z0-9+=])' {} \; >${tmpScan}

if [[ -s ${tmpScan} ]]; then
    echo "AWS SECRET ACCESS KEYS must not be checked into GitHub"
    exit 1
fi

find "${SCAN_WORKSPACE}" -type f -not -path '*/\.*' -exec grep -HP "Authorization['\"=, ]+[a-zA-Z0-9\\-]{20,}" {} \; >${tmpScan}

if [[ -s ${tmpScan} ]]; then
    echo "Authorization headers must not be checked into GitHub"
    exit 1
fi

find "${SCAN_WORKSPACE}" -type f -not -path '*/\.*' -not -path '*/*.rst' -exec grep -HP "[a-z]{4,}:\/\/[^:\/]+:[^@]+@.+" {} \; >${tmpScan}

if [[ -s ${tmpScan} ]]; then
    echo "HTTP basic authentication must not be checked into GitHub"
    exit 1
fi