# Prepare slave for run test

## Preparation scripts and sequence (*+current order is important+*)

### Generate and copy slave ssh key to max-tst-01:
```bash
ssh-keygen -t rsa
cat .ssh/id_rsa.pub | ssh vagrant@max-tst-01.mariadb.com 'cat >> .ssh/authorized_keys' # will ask for vagrant password
```


### Run script (from MDBCI folder):
```bash
./scripts/setup_as_slave.sh
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
Cmnd_Alias VAGRANT_EXPORTS_REMOVE = /bin/sed -r -e * d -ibak /tmp/exports
%sudo ALL=(root) NOPASSWD: VAGRANT_EXPORTS_ADD, VAGRANT_NFSD_CHECK, VAGRANT_NFSD_START, VAGRANT_NFSD_APPLY, VAGRANT_EXPORTS_REMOVE, VAGRANT_EXPORTS_COPY
```

### Relogin
```bash
exec su $USER
```

## Disable some authentifications for ssh (without it Jenkins unable to connect to slave)

### Find in '/etc/ssh/sshd_config' on slave this lines and comment them:
```bash
Ciphers aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,hmac-ripemd160
KexAlgorithms diffie-hellman-group-exchange-sha256,diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1
```

### Restart ssh:
```bash
service ssh restart
```
