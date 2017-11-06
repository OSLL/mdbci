# Install MDBCI dependencies

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

ubuntu_codename=$(cat /etc/*release 2>/dev/null | grep "UBUNTU_CODENAME" | awk -F'=' '{print $2}')
if [[ -z "$ubuntu_codename" ]]; then
    ubuntu_codename=$(cat /etc/*release 2>/dev/null | grep "DISTRIB_CODENAME" | awk -F'=' '{print $2}')
fi

checkStatus sudo apt-get update

checkStatus sudo apt-get install git build-essential -y

checkStatus ./scripts/setup_aws.sh

# Vagrant and prerequisites
checkStatus sudo apt-get install ruby libxslt-dev \
                                      libxml2-dev \
                                      libvirt-dev \
                                      zlib1g-dev -y
checkStatus sudo gem install ipaddress
checkStatus sudo gem install json-schema -v 2.6.2
if [[ $(vagrant --version) != "Vagrant 1.8.1" ]]; then
        checkStatus wget https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1_x86_64.deb
        checkStatus sudo dpkg -i vagrant_1.8.1_x86_64.deb
        checkStatus rm vagrant_1.8.1_x86_64.deb
fi

checkStatus vagrant plugin install vagrant-aws --plugin-version 0.7.2
checkStatus vagrant plugin install vagrant-libvirt --plugin-version 0.0.33
checkStatus vagrant plugin install vagrant-mutate --plugin-version 1.2.0
checkStatus vagrant plugin install vagrant-omnibus --plugin-version 1.5.0
checkStatus vagrant box add --force dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box

# Libvirt and tools(virsh, virt-clone)
checkStatus sudo apt install qemu-kvm \
                             libvirt-bin \
                             virtinst -y
checkStatus sudo adduser $USER libvirtd

# Configuration of libvirt images path
checkStatus sudo virsh pool-destroy default
checkStatus sudo virsh pool-undefine default
checkStatus mkdir -p $HOME/libvirt-images
checkStatus cp ./scripts/slave_setting/libvirt/default.xml ./scripts/slave_setting/libvirt/default_tmp.xml
checkStatus sed -i "s|#REPLACE_ME#|$HOME/libvirt-images|g" ./scripts/slave_setting/libvirt/default_tmp.xml
checkStatus sudo virsh pool-create ./scripts/slave_setting/libvirt/default_tmp.xml
checkStatus sudo virsh pool-dumpxml --pool default > ./scripts/slave_setting/libvirt/default_tmp.xml
checkStatus sudo virsh pool-define ./scripts/slave_setting/libvirt/default_tmp.xml
checkStatus sudo virsh pool-autostart default
checkStatus rm ./scripts/slave_setting/libvirt/default_tmp.xml


# Docker
checkStatus sudo apt-get update
checkStatus sudo apt-get install apt-transport-https \
                                 ca-certificates -y
checkStatus sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
checkStatus echo "deb https://apt.dockerproject.org/repo ubuntu-$ubuntu_codename main" | sudo tee /etc/apt/sources.list.d/docker.list
checkStatus sudo apt-get update
#sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual
checkStatus sudo apt-get install "docker-engine=1.11.0-0~$ubuntu_codename" -y --allow-downgrades
checkStatus sudo groupadd -f docker
checkStatus sudo usermod -aG docker $USER


# After that user shoud logout and login
# exec su $USER
