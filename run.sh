#!/bin/bash
set -e
BASE_DIR="$(cd -P "$(dirname "$BASH_SOURCE")" && pwd -P)"
cd "${BASE_DIR}"

TOOLS_WORKSPACE="${WORKSPACE}"
args=()
MODE=""

me=$(basename "$0")
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
  -w | --workspace)
    shift # past argument
    TOOLS_WORKSPACE="$1"
    # shift
    ;;
  -r | --require)
    shift # past argument
    REQUIRED_VERSION="$1"
    # shift
    ;;
  -m | --mode)
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

TOOLS_REPO="sts-tools"

mkdir -p "${HOME}/.tmp"
aws_dir=$(mktemp -d --tmpdir="${HOME}/.tmp" -t aws_XXXXXXXXXX)

mkdir -p ${HOME}/.aws/cli/cache
cp -a ${HOME}/.aws/* "${aws_dir}/"
chmod ugo+rxw "${aws_dir}"
chmod -R ugo+rw "${aws_dir}"

set +e
docker run \
  --dns 8.8.8.8 \
  --rm \
  --env WHO=$(whoami) \
  --env REQUIRED_VERSION="${REQUIRED_VERSION}" \
  --user 1000:$(getent group docker | cut -d ':' -f 3) \
  --interactive \
  --tty \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --volume ${TOOLS_WORKSPACE}:/home/workspace \
  --volume ${aws_dir}:/home/tools/.aws \
  --volume /tmp:/tmp \
  ${TOOLS_REPO}:latest \
  "${args[@]}"

ERROR=$?

cp -a ${aws_dir}/cli/cache/* ${HOME}/.aws/cli/cache/
rm -rf ${aws_dir}

exit ${ERROR}
