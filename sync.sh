#!/bin/bash
set -e
BASE_DIR="$( cd -P "$( dirname "$BASH_SOURCE" )" && pwd -P )"
cd "${BASE_DIR}"

NO_PUSH="NO"
FIX="NO"
CLEAN="NO"
REFORMAT="NO"
me=`basename "$0"`
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -f|--fix)
      FIX="YES"
      shift # past argument
      ;;
    -c|--clean)
      CLEAN="YES"
      shift # past argument
      ;;
    -r|--reformat)
      REFORMAT="YES"
      shift # past argument
      ;;
    --no-push)
      NO_PUSH="YES"
      shift # past argument
      ;;
    *)    # unknown option
      echo "Usage ${me} [-f|--fix] [-c|--clean] [-r|--reformat] [--no-push]"
      echo "Unknown option ${key}"
      exit 1
      ;;
  esac
done

function doRepo(){
    repo=$1
    type=$2
    echo "${repo} ${type}"

    cd ${repo}
    ISSUES=""
    declare -a files=(
        "LICENSE"
        ".gitignore"
        "init.sh"
        "push.sh"
        "pull.sh"
        "release.sh"
        "build.sh"
        "deploy.sh"
        "Dockerfile"
        "entrypoint.sh"
        "Jenkinsfile"
        "run.sh"
        "reformat.sh"
    )

    for f in "${files[@]}"
    do
        echo "check $f"

        if [[ "${f}" =~ (LICENSE|.gitignore) ]]; then
            SOURCE_DIR="${BASE_DIR}"
        else
            if [[ "${type}" == "Tests" ]]; then
                continue
            fi

            if [[ "${f}" =~ (push.sh|release.sh) ]]; then
                if [[ "${type}" != "IaC" ]]; then
                    continue
                fi
            elif [[ "${f}" =~ (init.sh) ]]; then
                if [[ ! "${type}" =~ (IaC|Manual|Docker) ]]; then
                    continue
                fi
            else
                if [[ "${type}" != "IaC" ]]; then
                    continue
                fi
            fi

            if [[ "${f}" =~ (build.sh|deploy.sh|Dockerfile|entrypoint.sh|Jenkinsfile|run.sh|reformat.sh) ]]; then
                SOURCE_DIR="${BASE_DIR}/common/IaC"
            else
                SOURCE_DIR="${BASE_DIR}/"
            fi
        fi

        if [[ -s $f ]]; then
          if [[ "${type}" == "IaC" ]]; then
            if [[ "${f}" =~ (build.sh|deploy.sh|Dockerfile|entrypoint.sh|import.sh|pull.sh|reformat.sh|run.sh|push.sh|init.sh|release.sh) ]]; then
              MSG="Duplicate file $f"
              echo "${MSG}"
              ISSUES+="${repo}: ${MSG}"
              ISSUES+=$'\n'

              if [[ "${FIX}" == "YES" ]]; then
                  rm "$f"
              fi
            else
              tmpDiff=$(mktemp -t diff-XXXXXXXXX)
              diff "${SOURCE_DIR}/$f" $f |tee ${tmpDiff}

              if [[ -s ${tmpDiff} ]]; then
                  MSG="Differences in file $f"
                  echo "${MSG}"
                  ISSUES+="${repo}: ${MSG}"
                  ISSUES+=$'\n'
                  if [[ "${FIX}" == "YES" ]]; then
                      cp "${SOURCE_DIR}/$f" .
                  fi
              fi
            fi
          else
            tmpDiff=$(mktemp -t diff-XXXXXXXXX)
            diff "${SOURCE_DIR}/$f" $f |tee ${tmpDiff}

            if [[ -s ${tmpDiff} ]]; then
                MSG="Differences in file $f"
                echo "${MSG}"
                ISSUES+="${repo}: ${MSG}"
                ISSUES+=$'\n'
                if [[ "${FIX}" == "YES" ]]; then
                    cp "${SOURCE_DIR}/$f" .
                fi
            fi
          fi
        else
          if [[ "${type}" == "IaC" ]] && [[ "${f}" =~ (build.sh|deploy.sh|Dockerfile|entrypoint.sh|import.sh|pull.sh|reformat.sh|run.sh|push.sh|init.sh|release.sh) ]]; then
            echo "no duplicate ${f}"
          else
            MSG="Missing file $f"
            echo "${MSG}"
            ISSUES+="${repo}: ${MSG}"
            ISSUES+=$'\n'

            if [[ "${FIX}" == "YES" ]]; then
                cp "${SOURCE_DIR}/$f" .
            fi
          fi
        fi
    done

    if [[ "${ISSUES}" != "" ]]; then

        if [[ "${FIX}" == "YES" ]]; then
            git add .
            git commit -m "${ISSUES}"

            if [[ "${NO_PUSH}" == "NO" ]]; then
                git push
            fi
        fi
    fi

    if [[ -f init.sh ]]; then
        chmod u+rwx,o-wx *.sh
    fi

    if [[ "${REFORMAT}" == "YES" ]]; then
        if [[ -s "reformat.sh" ]]; then

            ./reformat.sh
            git add .

            set +e
            git commit -m "Automated reformat"
            status=$?
            set -e

            if [[ $status -eq 0 ]]; then

                if [[ "${NO_PUSH}" == "NO" ]]; then
                    git push
                fi
            fi
        fi
    fi

    cd ..
}

declare -a repos=(
    "dga-network-infrastructure"
    "dga-golden-image"
    "dga-jenkins-infrastructure"
    "dga-push_pull-deploy"
    "dga-ckan_web"
    "dga-selenium-tests"
    "dga-ckan_web-infrastructure"
    "dga-roles"
    "dga-ngix"
    "dga-ngix-infrastructure"
    "dga-solr"
    "dga-solr-infrastructure"
    "dga-geoserver"
    "dga-services"
    "dga-start_of_day"
    "dga-end_of_day"
    "dga-configure"
)

if [[ "${CLEAN}" == "YES" ]]; then
  rm -rf .repos
fi

mkdir -p .repos

cd .repos
for repo in "${repos[@]}"
do

    if [[ ! -d ${repo} ]]; then
        echo "clone ${repo}"
        git clone -q git@github.com:ausdto/${repo}.git ${repo}
    fi

    cd ${repo}

    git checkout Develop
    cd ..
done

ALL_ISSUES=""
for repo in "${repos[@]}"
do
    type="common"
    if [[ "${repo}" == "dga-selenium-tests" ]]; then
        type="Tests"
    elif [[ "${repo}" =~ (dga-configure) ]]; then
        type="Manual"
    elif [[ "${repo}" =~ ^(dga-ckan_web|dga-ngix|dga-solr|dga-geoserver|dga-services)$ ]]; then
        type="Docker"
    elif [[ "${repo}" =~ (dga-tools) ]]; then
        echo "ERROR: self reference"
        exit 1
    else
        type="IaC"
    fi

    doRepo ${repo} ${type}

    if [[ "${ISSUES}" != "" ]]; then
        ALL_ISSUES+="${ISSUES}"
        ALL_ISSUES+=$'\n'
    fi
done

rm -rf .repos

if [[ "${ALL_ISSUES}" != "" ]]; then
    echo ""
    echo "${ALL_ISSUES}"
    if [[ "${FIX}" != "YES" ]]; then
        echo "FAILED"
        exit 1
    fi
fi
