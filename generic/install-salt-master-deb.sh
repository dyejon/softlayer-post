#!/bin/bash

exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/root/postinstall.log 2>&1

set -x

# docker repo
apt-get update
apt-get install -y apt-transport-https ca-certificates
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo 'deb https://apt.dockerproject.org/repo debian-jessie main' | tee /etc/apt/sources.list.d/docker.list
apt-get update

# docker install
apt-get install -y docker-engine

# packer install
apt-get install -y unzip
cd /tmp 
wget https://releases.hashicorp.com/packer/0.10.1/packer_0.10.1_linux_amd64.zip
unzip packer*
mv packer /usr/local/bin/

# saltmaster build
cd /root/
apt-get install -y git
git clone https://repo.hovitos.engineering/devops/horizon-packer-imaging.git
cd horizon-packer-imaging
git checkout nopush
cd saltmaster
. vars
packer build *.json

# run saltmaster
docker run -d \
	--name=saltmaster \
	--restart=always \
	-p 4505:4505 \
	-p 4506:4506 \
	-v /vol/saltmaster/etc/salt/master.d:/etc/salt/master.d:ro \
	-v /vol/saltmaster/etc/salt/roster.d:/etc/salt/roster.d:ro \
	-v /vol/saltmaster/etc/salt/pki:/etc/salt/pki \
	-v /vol/saltmaster/srv:/srv \
	salt/saltmaster:${VERSION} \
	salt-master

# set aliases 
cat <<\EOF > /etc/profile.d/salt.sh
#!/bin/bash
alias salt='docker exec -ti saltmaster salt'
alias salt-key='docker exec -ti saltmaster salt-key'
alias salt-run='docker exec -ti saltmaster salt-run'
alias salt-cp='docker exec -ti saltmaster salt-cp'
EOF

chmod +rx /etc/profile.d/salt.sh

# vim: set ts=4 sw=4 expandtab:
