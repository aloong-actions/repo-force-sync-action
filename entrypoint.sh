#!/bin/sh

set -e

# args defined in actions.yml
SOURCE_HOST=$1
SOURCE_REPO=$2
SOURCE_BRANCH=$3
DESTINATION_HOST=$4
DESTINATION_REPO=$5
DESTINATION_BRANCH=$6

## check whilelist
# check source host
export is_src_permitted=false
while read src_host;
do
  if [ "${src_host}" = "${SOURCE_HOST}" ]; then
    is_src_permitted=true
  fi
done < <(cat /whitelist.json |jq -r '.source.hosts[]')

if [ $is_src_permitted = false ]; then
    echo "The source host ${SOURCE_HOST} is not permitted, please file PR to apply for whitelist permission."
    exit 1
fi

# check dest host
is_dst_permitted=false
# strip the subdomain and retain the level 2 domain, e.g.: a.b.github.com -> github.com
DESTINATION_DOMAIN=`echo $DESTINATION_HOST | awk -F"." 'BEGIN{OFS="\."}{print $(NF-1), $NF}'`
while read dst_host;
do
  if [ "${DESTINATION_DOMAIN}" = "$dst_host" ]; then
    # check dest orginization
    is_dst_org_permitted=false
    DESTINATION_ORG=`echo $DESTINATION_REPO | cut -d '/' -f 1 | awk '{print tolower($0)}'`
    while read dest_org;
    do
      dest_org=`echo $dest_org | awk '{print tolower($0)}'`
      if [ "${dest_org}" = "all" ]; then
        is_dst_org_permitted=true
        break
      elif [ "${dest_org}" = "${DESTINATION_ORG}" ]; then
        is_dst_org_permitted=true
        break
      fi
    done < <(cat /whitelist.json |jq -r --arg h "$dst_host" '.dest[] | select(.host==$h).orgs[]')

    if [ "$is_dst_org_permitted" = false ]; then
      echo "The dest orgnization ${DESTINATION_ORG} is not permitted, please file PR to apply for whitelist permission."
      exit 1
    else
      is_dst_permitted=true
      break
    fi # end of dest orginization check
  fi

done < <(cat /whitelist.json |jq -r '.dest[] | .host')

if [ "$is_dst_permitted" = false ]; then
    echo "The dest host ${DESTINATION_HOST} is not permitted, please file PR to apply for whitelist permission."
    exit 1
fi

if [[ -n "$SOURCE_SSH_PRIVATE_KEY" ]]; then
  mkdir -p /root/.ssh
  echo "$SOURCE_SSH_PRIVATE_KEY" | sed 's/\\n/\n/g' >/root/.ssh/src_rsa
  chmod 600 /root/.ssh/src_rsa
fi

if [[ -n "$DESTINATION_SSH_PRIVATE_KEY" ]]; then
  mkdir -p /root/.ssh
  echo "$DESTINATION_SSH_PRIVATE_KEY" | sed 's/\\n/\n/g' >/root/.ssh/dst_rsa
  chmod 600 /root/.ssh/dst_rsa
fi

mkdir -p ~/.ssh
cp /root/.ssh/* ~/.ssh/ 2>/dev/null || true

sh -c "/git-sync.sh $*"
