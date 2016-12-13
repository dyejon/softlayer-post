#!/bin/bash

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/root/postinstall.log 2>&1

set -x


# install
apt-get update
apt-get install -y wget jq apt-transport-https
wget -O - https://repo.saltstack.com/apt/debian/8/amd64/2016.3/SALTSTACK-GPG-KEY.pub | apt-key add -
echo 'deb https://repo.saltstack.com/apt/debian/8/amd64/2016.3/ jessie main' | tee /etc/apt/sources.list.d/saltstack.list
apt-get update
apt-get install -y salt-minion


# reconfigure
## prefer argument, then user data
SALT_MASTER="$1"

if [ -z "$SALT_MASTER" ]; then
  SALT_MASTER=$(wget -O- https://api.service.softlayer.com/rest/v3/SoftLayer_Resource_Metadata/getUserMetadata.json 2>/dev/null | jq -M -r . | jq -M -r '.["salt-master"]' | grep -v null)
fi

if [ -z "$SALT_MASTER" ]; then
  echo >&2 "could not determine salt master address, will not reconfigure"
  exit 1
fi

systemctl stop salt-minion
echo "master: ${SALT_MASTER}" >/etc/salt/minion.d/master.conf
rm -rf /etc/salt/pki/minion 
systemctl start salt-minion
