#ubuntu_codename=$(cat /etc/*release 2>/dev/null | grep "UBUNTU_CODENAME" | awk -F'=' '{print $2}')
#if [[ -z "$ubuntu_codename" ]]; then
#    ubuntu_codename=$(cat /etc/*release 2>/dev/null | grep "DISTRIB_CODENAME" | awk -F'=' '{print $2}')
#fi

sudo yum clean all
sudo yum install git build-essential wget -y
sudo yum groupinstall "Development Tools" -y

# Vagrant and prerequisites
sudo yum  install ruby libxslt-devel \
                          libxml2-devel \
                          libvirt-devel \
                          zlib-devel -y
sudo gem install ipaddress
sudo gem install json-schema -v 2.6.2
if [[ $(vagrant --version) != "Vagrant 1.8.1" ]]; then
        wget https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1_x86_64.rpm
        sudo rpm -i vagrant_1.8.1_x86_64.rpm
        rm vagrant_1.8.1_x86_64.rpm
fi
vagrant plugin install vagrant-vbguest
vagrant plugin install vagrant-aws
vagrant plugin install vagrant-libvirt --plugin-version 0.0.33
vagrant plugin install vagrant-mutate
vagrant plugin install vagrant-omnibus

# Libvirt and tools(virsh, virt-clone)
sudo yum install qemu-kvm \
                 libvirt\
                 -y
sudo yum groupinstall "Virtualization Tools" -y
sudo adduser $USER libvirtd

# Configuration of libvirt images path
sudo virsh pool-destroy default
sudo virsh pool-undefine default
mkdir -p $HOME/libvirt-images
sudo virsh pool-create ./scripts/slave_setting/libvirt/default.xml
sudo virsh pool-dumpxml --pool default > ./scripts/slave_setting/libvirt/default_tmp.xml
sudo virsh pool-define ./scripts/slave_setting/libvirt/default_tmp.xml
sudo virsh pool-autostart default


# Docker
curl -sSL https://get.docker.com/ | sh
sudo service docker start
sudo groupadd docker
sudo usermod -aG docker $USER


# After that user shoud logout and login
# exec su $USER
