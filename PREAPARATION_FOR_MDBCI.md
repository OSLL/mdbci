# Prepare machine for mdbci

## Preparation scripts and sequence (*current order is important*)

### Before installation
Check if yoe have Docker, Vagrant, Virsh, Libvirt installed. It's better to remove this packages before MDBCI dependencies installation, because MDBCI depends on certain versions of packages.

### Run scripts(from MDBCI folder) in next order:
```bash
./scripts/install_mdbci_dependencies.sh
./scripts/slave_setting/repo_setup.sh
```

### After that you need to logout and login
```bash
exec su $USER
```

### And you need to prepare vagrant user with all needed privileges
Add to the */etc/sudoers.d/vagrant* next lines:
```bash
Cmnd_Alias VAGRANT_EXPORTS_ADD = /usr/bin/tee -a /etc/exports
Cmnd_Alias VAGRANT_EXPORTS_COPY = /bin/cp /tmp/exports /etc/exports
Cmnd_Alias VAGRANT_NFSD_CHECK = /etc/init.d/nfs-kernel-server status
Cmnd_Alias VAGRANT_NFSD_START = /etc/init.d/nfs-kernel-server start
Cmnd_Alias VAGRANT_NFSD_APPLY = /usr/sbin/exportfs -ar
Cmnd_Alias VAGRANT_EXPORTS_REMOVE = /bin/sed -r -e * d -ibak /tmp/exp
%sudo ALL=(root) NOPASSWD: VAGRANT_EXPORTS_ADD, VAGRANT_NFSD_CHECK, VAGRANT_NFSD_START, VAGRANT_NFSD_APPLY, VAGRANT_EXPORTS_REMOVE, VAGRANT_EXPORTS_COPY
```

### Now we need to configure IP v6 support
#### Docker
```
service docker stop
docker daemon --ipv6 &
```

#### Libvirt
Run
```
virsh net-edit default
```
Make changes so it looks like that(ip v6 field must exist)
```
virsh net-dumpxml default
<network connections='1'>
  <name>default</name>
  <uuid>fbe03136-3bfc-4b2f-9817-7a21a757a6ec</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='52:54:00:50:f4:f2'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
  <ip family='ipv6' address='2000:abcd:1:dead::1' prefix='64'>
  </ip>
</network>
```

### AWS command line tool installation

If tests use AWS command line tool:

```
pip install --upgrade --user awscli
```

and put configuration and credential files into ~/.aws/


Config file example:
```
[default]
region=eu-west-1
output=json
```

Credentials file:
```
[default]
aws_access_key_id=XXXXXXXXXXXXXXXXXXXX
aws_secret_access_key=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

In some cases following command is needed before _pip install_

```
export LC_ALL="en_US.UTF-8"
```

If AWS CLi tool still does not work:
```
sudo pip install awscli --force-reinstall --upgrade
```
