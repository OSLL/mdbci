ubuntu_codename=$(cat /etc/*release 2>/dev/null | grep "UBUNTU_CODENAME" | awk -F'=' '{print $2}')
if [[ -z "$ubuntu_codename" ]]; then
    ubuntu_codename=$(cat /etc/*release 2>/dev/null | grep "DISTRIB_CODENAME" | awk -F'=' '{print $2}')
fi

sudo apt-get install git build-essential -y

# Vagrant and prerequisites
sudo apt-get install ruby libxslt-dev \
                          libxml2-dev \
                          libvirt-dev \
                          zlib1g-dev -y
sudo gem install ipaddress
sudo gem install json-schema
if [[ $(vagrant --version) != "Vagrant 1.8.1" ]]; then
        wget https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1_x86_64.deb
        sudo dpkg -i vagrant_1.8.1_x86_64.deb
        rm vagrant_1.8.1_x86_64.deb
fi
vagrant plugin install vagrant-vbguest
vagrant plugin install vagrant-aws
vagrant plugin install vagrant-libvirt
vagrant plugin install vagrant-mutate
vagrant plugin install vagrant-omnibus

# Libvirt and tools(virsh, virt-clone)
sudo apt install qemu-kvm \
                 libvirt-bin \
                 virtinst -y
sudo adduser $USER libvirtd

# Configuration of libvirt images path
sudo virsh pool-destroy default
mkdir -p libvirt-images
sudo virsh pool-create ./scripts/slave_setting/libvirt/default.xml
sudo virsh pool-define ./scripts/slave_setting/libvirt/default.xml
sudo virsh pool-autostart default


# Docker
sudo apt-get update
sudo apt-get install apt-transport-https \
                     ca-certificates -y
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo ubuntu-$ubuntu_codename main" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
#sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual
sudo apt-get install "docker-engine=1.11.0-0~$ubuntu_codename" -y
sudo groupadd docker
sudo usermod -aG docker $USER


# After that user shoud logout and login
# exec su $USER
