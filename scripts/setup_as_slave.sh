#!/bin/bash

./scripts/install_mdbci_dependencies.sh
./scripts/slave_setting/repo_setup.sh
./scripts/slave_setting/install_run_test_dependencies.sh
./scripts/slave_setting/create_auxiliary_dirs.sh
./scripts/slave_setting/import_gpg.sh
./scripts/slave_setting/configure_ctest_parsing_and_performance.sh

sudo apt-get install nfs-kernel-server -y

var='''Cmnd_Alias VAGRANT_EXPORTS_ADD = /usr/bin/tee -a /etc/exports\n
Cmnd_Alias VAGRANT_EXPORTS_COPY = /bin/cp /tmp/exports /etc/exports\n
Cmnd_Alias VAGRANT_NFSD_CHECK = /etc/init.d/nfs-kernel-server status\n
Cmnd_Alias VAGRANT_NFSD_START = /etc/init.d/nfs-kernel-server start\n
Cmnd_Alias VAGRANT_NFSD_APPLY = /usr/sbin/exportfs -ar\n
Cmnd_Alias VAGRANT_EXPORTS_REMOVE = /bin/sed -r -e * d -ibak /tmp/exports\n
%sudo ALL=(root) NOPASSWD: VAGRANT_EXPORTS_ADD, VAGRANT_NFSD_CHECK, VAGRANT_NFSD_START, VAGRANT_NFSD_APPLY, VAGRANT_EXPORTS_REMOVE, VAGRANT_EXPORTS_COPY'''

sudo sh -c "echo \"$var\" > /etc/sudoers.d/vagrant"
