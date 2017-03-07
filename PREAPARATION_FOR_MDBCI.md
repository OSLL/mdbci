# Prepare machine for mdbci

## Preparation scripts and sequence (*+current order is important+*)

### Generate and copy slave ssh key to max-tst-01:
```bash
ssh-keygen -t rsa
cat .ssh/id_rsa.pub | ssh vagrant@max-tst-01.mariadb.com 'cat >> .ssh/authorized_keys' # will ask for vagrant password
```

### Run scripts(from MDBCI folder) in next order:
```bash
./scripts/install_mdbci_dependencies.sh
./scripts/slave_setting/repo_setup.sh
```

### After that you need to logout and login
```bash
exec su $USER
```

### *IMPORTANT* Vagrant needs additional package - *nfs-server-kernel*:
```bash
sudo apt-get install nfs-kernel-server
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