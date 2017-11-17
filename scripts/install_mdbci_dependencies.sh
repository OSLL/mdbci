#!/bin/bash
# This script installs MDBCI dependencies and sets them up
# as required by the tool.

# Get the location of the script and go into that directory.
script_dir=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
cd $script_dir

# Function executes the passed command. If it is not successfull, then
# function shows the coman that have failed and exits from the script.
function checkStatus {
  "$@"
  local status=$?
  if [ $status -ne 0 ]; then
    output="[INSTALLATION ERROR]: $@"
    echo $output >&2
    exit $status
  fi
  return $status
}

# Function executes the passed command. If it is not successfull, then
# function shows that the command was not fully executed.
function warnOnError {
  "$@"
  local status=$?
  if [ $status -ne 0 ]; then
    echo "[ISTALLATION WARNING]: $@"
  fi
  return $status
}

# Try to find out the code name of the installed ubuntu release
ubuntu_codename=$(cat /etc/*release 2>/dev/null | grep "UBUNTU_CODENAME" | awk -F'=' '{print $2}')
if [[ -z "$ubuntu_codename" ]]; then
    ubuntu_codename=$(cat /etc/*release 2>/dev/null | grep "DISTRIB_CODENAME" | awk -F'=' '{print $2}')
fi

# Update the packages of the system and install git and build-essential packages
failOnError sudo apt-get update
failOnError sudo apt-get install -y git build-essential

# Install AWS, configure user and security group.
failOnError ./setup_aws.sh

# Install dependencies required for mdbci and Vagrant to run
failOnError sudo apt-get install -y ruby \
                                    libxslt-dev \
                                    libxml2-dev \
                                    libvirt-dev \
                                    zlib1g-dev
# Install ruby gems used by the mdbci
failOnError sudo gem install ipaddress
failOnError sudo gem install json-schema -v 2.6.2
# Install the Vagrant and plugins used by the mdbci
if [[ $(vagrant --version) != "Vagrant 1.8.1" ]]; then
        failOnError wget https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1_x86_64.deb
        failOnError sudo dpkg -i vagrant_1.8.1_x86_64.deb
        failOnError rm vagrant_1.8.1_x86_64.deb
fi
failOnError vagrant plugin install vagrant-aws --plugin-version 0.7.2
failOnError vagrant plugin install vagrant-libvirt --plugin-version 0.0.33
failOnError vagrant plugin install vagrant-mutate --plugin-version 1.2.0
failOnError vagrant plugin install vagrant-omnibus --plugin-version 1.5.0
failOnError vagrant box add --force dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box

# Install libvirt and tools to controll it including virsh, virt-clone
failOnError sudo apt install -y qemu-kvm \
                                libvirt-bin \
                                virtinst
# Allow user to manage libvirt daemon
failOnError sudo adduser $USER libvirtd

# Configure libvirt daemon images path
warnOnError sudo virsh pool-destroy default
warnOnError sudo virsh pool-undefine default
libvirt_images_directory="$HOME/libvirt-images"
failOnError mkdir -p $libvirt_images_directory
failOnError cp slave_setting/libvirt/default.xml slave_setting/libvirt/default_tmp.xml
failOnError sed -i "s|#REPLACE_ME#|$libvirt_images_directory|g" slave_setting/libvirt/default_tmp.xml
failOnError sudo virsh pool-create slave_setting/libvirt/default_tmp.xml
failOnError sudo virsh pool-dumpxml --pool default > slave_setting/libvirt/default_tmp.xml
failOnError sudo virsh pool-define slave_setting/libvirt/default_tmp.xml
failOnError sudo virsh pool-autostart default
failOnError rm slave_setting/libvirt/default_tmp.xml

# Install and setup docker
failOnError sudo apt-get update
failOnError sudo apt-get install apt-transport-https \
                                 ca-certificates -y
failOnError sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
failOnError echo "deb https://apt.dockerproject.org/repo ubuntu-$ubuntu_codename main" | sudo tee /etc/apt/sources.list.d/docker.list
failOnError sudo apt-get update
#sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual
failOnError sudo apt-get install "docker-engine=1.11.0-0~$ubuntu_codename" -y --allow-downgrades
failOnError sudo groupadd -f docker
failOnError sudo usermod -aG docker $USER


# After that user shoud logout and login
# exec su $USER
