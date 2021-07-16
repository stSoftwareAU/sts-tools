#!/bin/bash

set -e

function doInit()
{
  if [[ ! -d /home/workspace/IaC ]]; then 
    echo "Not A IaC workspace"
    exit 1
  fi 

  export WORKSPACE="/home/workspace/"

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

function doPush()
{
  ./push.sh
}

function doDeploy()
{
  ./deploy.sh
}

function doImport()
{
  ./import.sh $1 $2 
}

function doRelease()
{
  ./release.sh
}

function doReformat()
{
  ./reformat.sh
}

function doMode() 
{
  mode=$1
  if [[ -z "${mode}" ]]; then 
    echo "Mode not defined"
    exit 1
  fi

  case "$mode" in
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
    release)
      doRelease
      ;;
    deploy)
      doDeploy
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

  if [[ "${AREA}" =~ ^[pP]rod(|uction)$ ]]; then
    COLOR="\e[5m\e[35m" 
  elif [[ "${AREA}" =~ ^[sS]tag(|ing)$ ]]; then
    COLOR="\e[5m\e[34m" 
  elif [[ "${AREA}" =~ ^[sS]cratch$ ]]; then
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
  
doInit
doMode $1 $2 $3