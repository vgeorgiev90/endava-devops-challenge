#!/bin/bash -eux

# Install Ansible ubuntu 20
apt -y update && apt-get -y upgrade
apt -y install software-properties-common ansible unzip
curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec
wget https://releases.hashicorp.com/packer/1.6.5/packer_1.6.5_linux_amd64.zip -P /tmp
unzip /tmp/packer_1.6.5_linux_amd64.zip -d /usr/local/bin
