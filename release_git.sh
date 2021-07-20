#!/bin/bash
#
# Description:
# This script creates list of stories which were merged into master branch from the last release | SLEIP-1
#
# If you have any questions related to this script you can ask
# Ihor Pleshchuk <ihor.pleshchuk@openexc.com>
# Dennis Christilaw <dennis.christilaw@openexc.com>

# set -vx

## FUNCTIONS ##

# Log provided message to screen
function logToScreen() {
  if [ $# -le 1 ]; then
    echo "ERROR: Function logToScreen must be called with at least two arguments (1: Severity, 2-*: Message)"
    exit 12
  else
    severity=$1
    shift
    echo "`date -u +%Y-%m-%d\ %H:%M:%S` UTC: $severity "$@
  fi
}

## MAIN ##

if [ -z "${1}" ]; then
  echo "Usage: $0 <from tag>"
  exit 1
fi

FROM_TAG="$1"
BASENAME=$(basename $0)
SCRIPT_DIR=$(cd $(dirname $0); pwd)
TS=$(date +%Y%m%d)
## Add hardcoded release_name  --for example, add exisiting release name  ( release tag would be the previous and it needs to be comapred to)
#RELEASE_NAME="release_${TS}"
RELEASE_FOLDER="${SCRIPT_DIR}/'release_20210702'}"
OUTPUT_FILE="${SCRIPT_DIR}/story_list.txt"
> ${OUTPUT_FILE}

declare -a REPO_LIST=(
  'git@github.com:Knowledgevision/OE-Connect-Central-FE.git' 
  'git@github.com:Knowledgevision/OE-Connect-Central-BE.git' 
  'git@github.com:Knowledgevision/OE-Connect-Passport-FE.git' 
  'git@github.com:Knowledgevision/OE-Connect-Passport-BE.git'
  'git@github.com:Knowledgevision/OE-Connect-Infrastructure.git'
  )

if [[ -d "${RELEASE_FOLDER}" ]]; then
  logToScreen "[ERROR]" "${RELEASE_FOLDER} already exists"
  exit 1
else
  mkdir -p "${RELEASE_FOLDER}"
fi

# clones repositories
for repo in ${REPO_LIST[@]}; do
  cd "${RELEASE_FOLDER}"
  REPO_FOLDER=$(echo ${repo} | sed 's~.*Knowledgevision\/\(.*\)\.git~\1~')

  if [[ ! -d "${RELEASE_FOLDER}/${REPO_FOLDER}" ]]; then
    logToScreen "[INFO]" "${REPO_FOLDER} | Cloning repo into ${RELEASE_FOLDER}/${REPO_FOLDER}"
    git clone ${repo} || exit 1
  fi

  cd "${RELEASE_FOLDER}/${REPO_FOLDER}"
  if [[ -z $(git branch | grep '* master') ]]; then
    logToScreen "[INFO]" "${REPO_FOLDER} | Checkout to master branch"
    git checkout master || exit 1
  fi
  logToScreen "[INFO]" "${REPO_FOLDER} | Pulling the last changes"
  git pull || exit 1

  # creates release tag attached to HEAD
  logToScreen "[INFO]" "${REPO_FOLDER} | Adding release tag ${RELEASE_NAME} to HEAD"
  # git tag -d "${RELEASE_NAME}"
  # git push --delete origin "${RELEASE_NAME}" > /dev/null
  # continue
 ## git tag "${RELEASE_NAME}"
 ## git push origin "${RELEASE_NAME}" > /dev/null

  # gathering story numbers
  logToScreen "[INFO]" "${REPO_FOLDER} | Gathering information about commits"
  log=$(git --no-pager log --pretty=oneline --no-merges ${FROM_TAG}..${RELEASE_NAME} 2>&1)
  RC=$?
  if [[ ${RC} -eq 0 ]]; then
    while read -r line; do
      echo ${line} | tr a-z A-Z >> "${OUTPUT_FILE}"
    done < <(echo ${log} | grep -e '[A-Za-z]\+-[0-9]\+' -o)
  else
    logToScreen "[ERROR]" "${log}"
    exit ${RC}
  fi
done

[[ -d "${RELEASE_FOLDER}" ]] && rm -rf "${RELEASE_FOLDER}"

logToScreen "[INFO]" "Remove duplicates from list of stories"
SORTED_LIST=$(cat "${OUTPUT_FILE}" | sort -u)
echo "${SORTED_LIST}" > "${OUTPUT_FILE}"
logToScreen "[INFO]" "List of stories from the last release ${FROM_TAG}:"
for line in $(cat "${OUTPUT_FILE}"); do
  logToScreen "[INFO]" "${line}"
done