# Prepare machine to be part of MaxScale CI

## Install dependencies for BuildBot CI

### Install MDBCI and configure MDBCI

Install mdbci:

```bash
mkdir ~/mdbci/mdbci
wget http://max-tst-01.mariadb.com/ci-repository/mdbci -O ~/mdbci/mdbci
chmod +x ~/mdbci/mdbci
```

Install dependencies:

```bash
~/mdbci/mdbci setup-dependencies
```

Configure the MDBCI credentials:

```bash
~/mdbci/mdbci configure
```

After installation, re-initiate the SSH connection.

### Install Docker

Use the instructions on https://docs.docker.com/install/ to install the tooling.

Add the current user to the docker group:

```
sudo gpasswd -a $(whoami) docker
```

Move docker container registry to the `/home` directory, so it won't run out of the free space.

```
sudo service docker stop
sudo mv /var/lib/docker /home/docker
sudo ln -sf /home/docker /var/lib/docker
sudo service docker start
sudo docker swarm init
```

### Install MaxScale test dependencies

Clone the MaxScale and switch to the `develop` branch:

```
sudo apt install git

git clone https://github.com/mariadb-corporation/MaxScale.git
cd MaxScale
git checkout develop
```

Install the test dependencies

```
~/MaxScale/BUILD/install_test_build_deps.sh
```

### Setup connection to repository locations

Copy the ssh id key to the max-tst-01 server. If it is not present, generate it.

```
ssh-copy-id vagrant@max-tst-01.mariadb.com
```

Create directories:

```
mkdir ~/LOGS ~/repo ~/repository
```

Install the `sshfs` tool:

```
sudo apt install sshfs
```

Modify FUSE configuration file `/etc/fuse.conf` to allow mounting with correct auth:

```bash
user_allow_other
```

Mount them using `sshfs` and enable automatic remount:

```bash
cd ~/mdbci
./mdbci deploy-examples
./scripts/slave_setting/sshfs/check_resync_in_crone.sh
./scripts/slave_setting/sshfs/resync_shared_dirs.sh
```

### Copy all private configuration files for the build tasks

- `build_parser_db_password`
- `maxscale_gpg_keys/MariaDBManager-GPG-KEY.private`
- `maxscale_gpg_keys/MariaDBManager-GPG-KEY.public`

### BuildBot worker installation

Allow BuildBot master to connect to current machine via SSH.

Install required dependencies:

```
sudo apt install python3 python3-dev python3-virtualenv
```

From the BuildBot master go to the worker-management script, install and start workers:

```
./manage.py --host HOST install
./manage.py --host HOST start
```

## Setup Zabbix agent

See official manual on the matter: https://www.zabbix.com/documentation/4.2/manual/installation/install_from_packages/debian_ubuntu

Edit the `/etc/zabbix/zabbix_agentd.conf`.

## OLD INFO

### To setup current machine as slave run
`.scripts/setup_as_slave.sh`

### After that you need to logout and login
```bash
exec su $USER
```

## Descriptions of above script
in case script above failed you can do it manually by running scripts below

### Run scripts(from MDBCI folder) in next order:
Install MDBCI dependencies
```bash
./scripts/install_mdbci_dependencies.sh
```
Fetch repos (boxes, configs, MDBCI, maxscale repo with tests, load ssh keys)
```bash
./scripts/slave_setting/repo_setup.sh
```
Install dependencies for running Jenkins jobs like run_test
```bash
./scripts/slave_setting/install_run_test_dependencies.sh
```
Create logging dirs
```bash
./scripts/slave_setting/create_auxiliary_dirs.sh
```
Import keys for MariaDB packages
```bash
./scripts/slave_setting/import_gpg.sh
```
Set up databases
```bash
./scripts/slave_setting/configure_ctest_parsing_and_performance.sh
```
