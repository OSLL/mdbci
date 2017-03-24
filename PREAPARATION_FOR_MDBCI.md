# Prepare machine for mdbci

## Preparation scripts and sequence (*+current order is important+*)


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
