#!/bin/bash
set -e
BASE_DIR="$( cd -P "$( dirname "$BASH_SOURCE" )" && pwd -P )"
cd "${BASE_DIR}"

FIX="NO"
me=`basename "$0"`
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
    -f|--fix)
      FIX="YES"
      shift # past argument
      ;;
    *)    # unknown option
      echo "Usage ${me} [-f|--fix]"
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
        "release.sh"
    )

    for f in "${files[@]}"
    do
        echo "check $f"
        
        if [[ "${f}" =~ (LICENSE|.gitignore) ]]; then
            SOURCE_DIR="${BASE_DIR}"
        else
            if [[ "${type}" == "other" ]]; then
                continue
            fi

            if [[ "${f}" =~ (push.sh|release.sh) ]]; then
                if [[ "${type}" != "IaC" ]]; then
                    continue
                fi
            elif [[ "${f}" =~ (init.sh) ]]; then
                if [[ ! "${type}" =~ (IaC|manual) ]]; then
                    continue
                fi
            else
                if [[ "${type}" != "IaC" ]]; then
                    continue
                fi
            fi

            SOURCE_DIR="${BASE_DIR}/common"
        fi

        if [[ -s $f ]]; then
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
        else 
            MSG="Missing file $f"
            echo "${MSG}"
            ISSUES+="${repo}: ${MSG}"
            ISSUES+=$'\n'

            if [[ "${FIX}" == "YES" ]]; then
                cp "${SOURCE_DIR}/$f" .
            fi
        fi
    done
    
    if [[ "${ISSUES}" != "" ]]; then

        if [[ "${FIX}" == "YES" ]]; then
            git add .
            git commit -m "${ISSUES}"
            git push
        fi
    fi
    cd ..
}

declare -a repos=(
    "dga-ckan_web_container"
    "dga-ckan_web_infrastructure"
    "dga-configure"
    "dga-golden-image"
    "dga-jenkins-pipeline"  
    "dga-network-pipeline"  
    "dga-push_pull-deploy"
    "dga-scratch_shutdown"
    "dga-selenium-tests"
)

rm -rf .repos
mkdir -p .repos

cd .repos
for repo in "${repos[@]}"
do
    echo "clone ${repo}"
    if [[ ! -d ${repo} ]]; then
        git clone -q git@github.com:ausdto/${repo}.git ${repo}
    else
        cd ${repo}
        git pull
        cd ..
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
        type="other"
    elif [[ "${repo}" =~ (dga-configure|dga-ckan_web_container) ]]; then
        type="container"
    else
        type="IaC"
    fi

    doRepo ${repo} ${type}
   
    if [[ "${ISSUES}" != "" ]]; then
        ALL_ISSUES+="${ISSUES}"
        ALL_ISSUES+=$'\n'

    fi
done

if [[ "${ALL_ISSUES}" != "" ]]; then
    echo ""
    echo "${ALL_ISSUES}"
    if [[ "${FIX}" != "YES" ]]; then
        echo "FAILED"
        exit 1
    fi
fi
