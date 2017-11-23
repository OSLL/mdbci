# Prepare machine for mdbci

## Preparation scripts and sequence (*current order is important*)

### Before installation

MDBCI depends upon the _Docker_, _Vagrant_, _Virsh_ and _Libvirt_ packages.

However, as MDBCI depends upon _particular versions_ of these packages, it is
better to remove them, in case they are already installed, _before_ running
the installation scripts.

### Run scripts(from MDBCI folder) in following order:

*NOTE*: If you are using an _RPM_-based Linux distribution replace, in the
following, `install_mdbci_dependencies.sh` with `install_mdbci_dependencies_yum.sh`.

```bash
./scripts/install_mdbci_dependencies.sh
./scripts/slave_setting/repo_setup.sh
```
*NOTE*: If you do not have _awscli_ installed or credentials have not been
configured, you will be asked during the execution of
`./scripts/install_mdbci_dependencies.sh` to provide the following:

* _AWS Access Key ID_: ask around before running the script
* _AWS Secret Access Key_: ask around before running the script
* _Default region name_: `eu-west-1`
* _Default output format_: `json`

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

### Add IPv6 support
### Optional: if you intend to use Docker, need to configure IPv6 Docker support
#### Docker
```
service docker stop
dockerd --ipv6 &
```
### Optional: if you intend to use Libvirt, need to configure Libvirt IPv6 support
#### Libvirt
Run
```
virsh net-edit default
```
Add following line to *default* network configuration, between <network> tags:
```
<ip family='ipv6' address='2000:abcd:1:dead::1' prefix='64'>
</ip>
```

After changes, run command for see changed default network configuration:
```
virsh net-dumpxml default
```

Configuration will looks like that (ipv6 field must exist):
```
<network connections='1'>
  <name>default</name>
  <uuid>...</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr0' stp='on' delay='0'/>
  <mac address='...'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
  <ip family='ipv6' address='2000:abcd:1:dead::1' prefix='64'>
  </ip>
</network>
```
Then we need to restart network:
```
virsh net-destroy default
virsh net-start default
virsh net-autostart default
```

And you will see that ipv6 edded with command *ifconfig* (or *ip address*)
```
virbr0    Link encap:Ethernet  HWaddr ...
          ...
          inet6 addr: 2000:abcd:1:dead::1/64 Scope:Global
          ...
```


### Optional: if you intend to use AWS
#### AWS command line tool installation

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
