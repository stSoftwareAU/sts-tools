#!/usr/bin/env sh
#
# WARNING: Automatically copied from sts-tools
#
set -e

function doInit() {
  if test -f "store/terraform.tfstate"; then
    cp store/*.tfstate .
  fi

  ENV_FILE=".env"

  if [[ -f ${ENV_FILE} ]]; then
    source ${ENV_FILE}
    export $(grep -v "#" ${ENV_FILE} | cut -d= -f1)
  fi

  for f in .config/*.auto.tfvars.json; do
    if [[ -e "$f" ]]; then
      cp $f .
    fi
  done
}

function doStore() {
  cp *.tfstate store/
  if [[ -e tf.plan ]]; then
    cp tf.plan store/
  fi
}

function tryApply() {
  STATUS="FAILED"
  terraform plan ${NO_COLOR_ARG} -input=false -out=tf.plan $1 $2
  if [[ $? -ne 0 ]]; then
    return
  fi

  terraform apply -auto-approve ${NO_COLOR_ARG} -input=false tf.plan
  if [[ $? -ne 0 ]]; then
    return
  fi

  STATUS="OK"
}

function doApply() {
  doInit

  terraform init ${NO_COLOR_ARG} -input=false
  terraform validate ${NO_COLOR_ARG}

  set +e

  let n=0
  while true; do
    tryApply $1 $2
    if [[ "${STATUS}" == "OK" ]]; then
      break
    fi

    let n=n+1
    if [[ "$n" -ge ${ATTEMPTS:-1} ]]; then
      echo "Failed after ${n} attempts"
      exit 1
    fi

    echo "Retrying after ${PAUSE:-60} seconds. Attempt ${n} of ${ATTEMPTS:-1}"
    sleep ${PAUSE:-60}
  done
  set -e

  doStore
}

function doPlan() {
  doInit

  terraform init -input=false
  terraform validate
  terraform plan -input=false -out=tf.plan
}

function doValidate() {
  doInit

  terraform init -input=false
  terraform validate
}

function doState() {
  doInit

  terraform init -input=false
  terraform validate

  terraform state $1 $2
  doStore
}

function doImport() {
  doInit

  terraform init -input=false
  terraform validate

  terraform import $1 $2
  doStore
}

function doDestroy() {
  doInit
  terraform init -input=false
  terraform destroy -auto-approve -input=false
  doStore
}

function doShell() {
  doInit
  terraform init -input=false
  /bin/sh
}

# handle non-option arguments
if [[ $# -lt 1 ]]; then
  echo "$0: A minimum of one argument is expected"
  exit 3
elif [[ $# -gt 3 ]]; then
  echo "$0: A maximum of three argument are expected"
  exit 4
fi

mode=$1

case "${mode}" in
shell)
  doShell
  ;;
apply-no-color)
  NO_COLOR_ARG="-no-color"
  doApply $2 $3
  ;;
apply)
  doApply $2 $3
  ;;
plan)
  doPlan
  ;;
state)
  doState $2 $3
  ;;
import)
  doImport $2 $3
  ;;
destroy)
  doDestroy
  ;;
reformat)
  doReformat
  ;;
validate)
  doValidate
  ;;
*)
  echo "${mode}: Unknown mode"
  exit 5
  ;;
esac
