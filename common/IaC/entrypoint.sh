#!/usr/bin/env sh
#
# WARNING: Automatically copied from dga-tools
#
set -e

function doInit()
{
  if test -f "store/terraform.tfstate"; then
      cp store/*.tfstate .
  fi
  if test -f ".config/.config.auto.tfvars.json"; then
      cp .config/.config.auto.tfvars.json .
  fi
}

function doStore()
{
  cp *.tfstate store/
}

function doApply()
{
  doInit

  terraform init -input=false
  terraform validate
  terraform plan -input=false -out=tf.plan
  terraform apply -auto-approve -input=false tf.plan

  doStore
}

function doPlan()
{
  doInit

  terraform init -input=false
  terraform validate
  terraform plan -input=false -out=tf.plan
}

function doImport()
{
  doInit

  terraform init -input=false
  terraform validate
  terraform import $1 $2
  doStore
}

function doDestroy()
{
  doInit
  terraform init -input=false
  terraform destroy -auto-approve -input=false
  doStore
}

function doShell()
{
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

case "$mode" in
  shell)
    doShell
    ;;
  apply)
    doApply
    ;;
  plan)
    doPlan
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
  *)
    echo "${mode}: Unknown mode"
    exit 5
    ;;
esac
