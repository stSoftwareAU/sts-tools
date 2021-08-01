#!/bin/bash
set -e

function setWS()
{
  if [[ -z "${WORKSPACE}" ]]; then
    WORKSPACE="/home/workspace/"
  fi

  if [[ ! -d "${WORKSPACE}/IaC" ]]; then
    echo "WARNING: Not A IaC workspace: ${WORKSPACE}"
  fi

  export WORKSPACE
}

function doInit()
{
  setWS

  . ./init.sh
}

function doShell()
{
  /bin/bash
}

function doBuild()
{
  ./build.sh
}

function doPull()
{
  ./pull.sh
}

function doPlan()
{
  ./plan.sh
}

function doDestroy()
{
  ./run.sh --mode destroy
}

function doPush()
{
  ./push.sh
}

function doApply()
{
  ./build.sh
  ./run.sh --mode apply
}

function doState()
{
  ./build.sh
  ./state.sh $1 $2
}

function doImport()
{
  ./build.sh
  ./import.sh $1 $2
}

function doRelease()
{
  ./release.sh
}

function doMode()
{
  mode=$1
  if [[ -z "${mode}" ]]; then
    echo "Mode not defined"
    exit 1
  fi

  case "${mode}" in
    shell)
      doShell
      ;;
    repl)
      doREPL
      ;;
    build)
      doBuild
      ;;
    pull)
      doPull
      ;;
    push)
      doPush
      ;;
    plan)
      doPlan
      ;;
    destroy)
      doDestroy
      ;;
    release)
      doRelease
      ;;
    apply)
      doApply
      ;;
    init)
      doInit
      ;;
    state)
      doState $2 $3
      ;;
    import)
      doImport $2 $3
      ;;
    *)
      echo "${mode}: Unknown mode"
      exit 5
      ;;
  esac
}

function listChoices()
{
  clear

  if [[ "${AREA}" =~ ^[pP]roduction$ ]]; then
    COLOR="\e[5m\e[31m"
  elif [[ "${AREA}" =~ ^[sS]taging$ ]]; then
    COLOR="\e[5m\e[34m"
  elif [[ "${AREA}" =~ ^[Pp]ipeline$ ]]; then
    COLOR="\e[5m\e[35m"
  elif [[ "${AREA}" =~ ^[dD]evelop$ ]]; then
    COLOR="\e[5m\e[32m"
  else
    COLOR="\e[5m\e[41m"
  fi

  echo -e "\e[2mREPL \e[0m${DOCKER_REPO}:${COLOR}${AREA}\e[0m"
  echo ""
  echo "1) BUILD:   Build the docker image"
  echo "2) DEPLOY:  Deploy the IaC"
  echo "3) PUSH:    Push the docker image"
  echo "4) PULL:    Pull the docker image"
  echo "5) RELEASE: Release the docker image"
  echo "6) IMPORT:  Import a manually created element"
  echo "9) SHELL:   Bash shell"
  echo ""
  echo "0) EXIT"
}

# Read-Evaluate-Print Loop (REPL)
function doREPL()
{
  listChoices

  while IFS="" read -r -e -d $'\n' -p 'Choice> ' choice; do
    case "${choice}" in
      1)
        doMode build
        ;;
      2)
        doMode deploy
        ;;
      3)
        doMode push
        ;;
      4)
        doMode pull
        ;;
      5)
        doMode release
        ;;
      6)
        read -p 'Resource: ' resource
        read -p 'ID: ' id
        doMode import "${resource}" "${id}"
        ;;
      9)
        doMode shell
        ;;
      0)
        exit 0
        ;;
      *)
        echo "Unknown choice ${choice}"
        ;;
    esac
    echo ""
    read -n 1 -s -r -p "Press any key to continue"
    listChoices
  done
}

args=()
MODE=""
me=`basename "$0"`

while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -m|--mode)
      shift # past argument
      MODE="$1"
      ;;
    *)
      args+=("${1}")
      ;;
  esac

  shift
done

setWS
export HOME=/home/tools
export PATH="/home/tools:${PATH}"

if [[ -z "${MODE}" ]]; then
  exec "${args[@]}"
else

  if [[ ! -d "${WORKSPACE}/IaC" ]]; then
    echo "ERROR: Not A IaC workspace: ${WORKSPACE}"
    exit 1
  fi

  doInit
  doMode ${MODE} "${args[@]}"
fi
