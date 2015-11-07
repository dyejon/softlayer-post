#!/bin/bash

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/root/postinstall.log 2>&1

set -x

apt-get update
apt-get install -y wget
wget -O - https://repo.saltstack.com/apt/debian/latest/SALTSTACK-GPG-KEY.pub | sudo apt-key add -
echo 'deb http://repo.saltstack.com/apt/debian/latest jessie main' | tee /etc/apt/sources.list.d/saltstack.list
apt-get update
apt-get install -y salt-minion
systemctl stop salt-minion
echo "master: 10.121.145.125" | tee /etc/salt/minion.d/master.conf
rm -rf /etc/salt/pki/minion 
systemctl start salt-minion
