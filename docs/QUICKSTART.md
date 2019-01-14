# Quickstart

These instructions install the bare minimum that is required to run the MaxScale system test setup. This configuration requires about 10GB of memory to run.

## Install Dependencies

### CentOS

```
sudo yum -y install ceph-common libvirt libvirt-client libvirt-devel qemu-kvm git
sudo yum -y install https://releases.hashicorp.com/vagrant/2.2.0/vagrant_2.2.0_x86_64.rpm
```

### Debian/Ubuntu

```
sudo apt-get update
sudo apt-get -y install build-essential libxslt-dev libxml2-dev libvirt-dev wget git cmake
wget https://releases.hashicorp.com/vagrant/2.2.0/vagrant_2.2.0_x86_64.deb
sudo dpkg -i vagrant_2.2.0_x86_64.deb
rm vagrant_2.2.0_x86_64.deb
```

## Prepare the Environment

```
vagrant plugin install vagrant-libvirt --plugin-version 0.0.43
vagrant plugin install vagrant-aws --plugin-version 0.7.2
sudo mkdir /var/lib/libvirt/libvirt-images
sudo virsh pool-create-as default dir --target=/var/lib/libvirt/libvirt-images
sudo usermod -a -G libvirt $(whoami)
vagrant box add --force dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box

mkdir mdbci
cd mdbci
wget http://max-tst-01.mariadb.com/ci-repository/mdbci
chmod a+x mdbci

./mdbci generate-product-repositories
./mdbci deploy-examples
```

For configuring AWS access:
```
./mdbci configure
```
and put AWS credentials

After this, you need to log out and back in again. This needs to be done in order for the new groups to become active.

## Generate Configuration and Start VMs

You need to get example configuration out of the AppImage. The following command will place `confs` and `scripts` directory into the current working directory:

```
./mdbci deploy-examples
```

In order to generate configuration out of the sample template and create VMs run:

```
./mdbci generate -t confs/libvirt.json my-setup
./mdbci up my-setup
```

Once the last command finishes, you should have a working set of VMs in the `my-setup` subfolder.
