#!/bin/sh

set -e

SOURCE_HOST=$1
SOURCE_REPO=$2
SOURCE_BRANCH=$3
DESTINATION_HOST=$4
DESTINATION_REPO=$5
DESTINATION_BRANCH=$6

echo -e "Source host: $SOURCE_REPO  \nDest host: $DESTINATION_HOST"

if ! echo $SOURCE_REPO | grep -Eq ':|@|\.git\/?$'; then
  if [[ -n "$SOURCE_SSH_PRIVATE_KEY" ]]; then
    SOURCE_REPO="git@${SOURCE_HOST}:${SOURCE_REPO}.git"
    GIT_SSH_COMMAND="ssh -v"
  elif [[ -n "$SOURCE_ACCESS_TOKEN" ]]; then
    SOURCE_REPO="https://${SOURCE_ACCESS_TOKEN}@${SOURCE_HOST}/${SOURCE_REPO}.git"
  fi
fi

if ! echo $DESTINATION_REPO | grep -Eq ':|@|\.git\/?$'; then
  if [[ -n "$DESTINATION_SSH_PRIVATE_KEY" ]]; then
    DESTINATION_REPO="git@${DESTINATION_HOST}:${DESTINATION_REPO}.git"
    GIT_SSH_COMMAND="ssh -v"
  elif [[ -n "$DESTINATION_ACCESS_TOKEN" ]]; then
    DESTINATION_REPO="https://${DESTINATION_ACCESS_TOKEN}@${DESTINATION_HOST}/${DESTINATION_REPO}.git"
  fi
fi

echo "SOURCE=$SOURCE_REPO:$SOURCE_BRANCH"
echo "DESTINATION=$DESTINATION_REPO:$DESTINATION_BRANCH"

if [[ -n "$SOURCE_SSH_PRIVATE_KEY" ]]; then
  # Clone using source ssh key if provided
  git clone -c core.sshCommand="/usr/bin/ssh -i ~/.ssh/src_rsa" "$SOURCE_REPO" /root/source --origin source && cd /root/source
else
  git clone "$SOURCE_REPO" /root/source --origin source && cd /root/source
fi

git remote add destination "$DESTINATION_REPO"

# Pull all branches references down locally so subsequent commands can see them
git fetch source '+refs/heads/*:refs/heads/*' --update-head-ok

# Print out all branches
git --no-pager branch -a -vv

if [[ -n "$DESTINATION_SSH_PRIVATE_KEY" ]]; then
  # Push using destination ssh key if provided
  git config --local core.sshCommand "/usr/bin/ssh -i ~/.ssh/dst_rsa"
fi

git push destination "${SOURCE_BRANCH}:${DESTINATION_BRANCH}" -f
