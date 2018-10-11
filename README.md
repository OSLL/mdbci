# MariaDb continuous integration infrastructure (MDBCI)

[MDBCI](https://github.com/mariadb-corporation/mdbci) is a set of tools for testing MariaDB components on the wide set of configurations. The main features of MDBCI are:

* automatic creation of virtual machines according to the configuration template,
* automatic and reliable deploy of MariaDB, Galera, MaxScale and other packages to the created virtual machines,
* creation and management of virtual machine state snapshots,
* reliable destruction of created virtual machines.

## Architecture overview

MDBCI is a tool written in Ruby programming language. In order to ease the deployment of the tool the AppImage distribution is provided. It allows to use MDBCI as a standalone executable.

MDBCI uses the [Vagrant](https://www.vagrantup.com/) and a set of low-level tools to create virtual machines and reliably destroy them when the need for them is over. Currently the following Vagrant backends are supported:

* [Libvirt](https://libvirt.org/) to manage kvm virtual machines,
* Amazon EC2 virtual machines,
* Remote boxes.

MDBCI currently provides support for the following distributions:

* CentOS 6, 7
* Debian Jessie, Stretch
* RHEL 6, 7 via AWS
* SLES 12, 13, 15
* Ubuntu 14.04, 16.04 and 18.04

MDBCI uses the [Chef](https://www.chef.io/chef/) to deploy the applications onto the virtual machines. The recipes for deployment are provided along with the tool. Currently the following applications may be installed:

* MariaDB,
* MariaDB Columnstore,
* MariaDB Galera,
* MariaDB MaxScale,
* MySQL.

The list of repositories for application installation can be automatically updated.

In-depth architecture description is provided in the [separate document](docs/architecture.md).

## MDBCI Syntax

In this section mdbci commands are described. In order to get help in runtime just call mdbci with --help flag:

<pre>
  ./mdbci --help
</pre>
  
General syntax for mdbci is following:

```
mdbci [options] <show | setup | generate>
```

### Flags

-h, --help:
  Shows help screen

-t, --template [config file]:
  Use [config file] for running instance. By default 'instance.json' will be used as config template.

-b, --boxes [boxes file]:
  Use [boxes file] for existing boxes. By default 'boxes.json'  will be used as boxes file.

-n, --box-name [box name]:
  Use [box name] for existing box names.

-f, --field [box config field]:
  Use [box config field] for existing box config field.

-w, --override
  Override previous configuration

-c, --command
  Set command to run in sudo clause

-s, --silent
  Keep silence, output only requested info or nothing if not available

-r, --repo-dir
  Change default place for repo.d

-p, --product
  Product name for setup repo and install product commands. Currently supported products: **MySQL**, **MariaDB**, **Galera**, **Maxscale**.

-v, --product-version
  Product version for setup repo and install product commands.

-e, --template_validation_type
  Template validation type (aws, no_aws)

-sn, --snapshot-name
  name of the snapshot

--ipv6
  if ipv6 must be added to network_config (also enables ipv6 for libvirt)

### Commands:

  show [boxes, boxinfo, platforms, versions, network, repos [config | config/node], keyfile [config/node], validate_template ]

  generate

  setup [boxes]

  sudo --command 'command arguments' config/node

  ssh --command 'command arguments' config/node

  setup_repo --product 'product name' --product-version 'product_version' config/node
    Setup product repo on the specified config/node. Install repo and update repo on th node/
    Product name and its version are defined by **--product** and **--product-version** command option.
    **P.S.** SSH access to the **MDBCI** boxes needs **NOPASSWD:ALL** option in the **/etc/sudoers** file for the mdbci ssh user.

  **install_product --product maxscale config/node**
    Install specified product by command option **--product** on a config/node. Currently supported only **Maxscale** product.

  validate_template -e aws -template TEMPLATE

  snapshot list --path-to-nodes T --node-name N

  snapshot [take, revert, delete] --path-to-nodes T [ --node-name N ] --snapshot-name S

  clone ORIGIN_CONFIG NEW_CONFIG_NAME

### Examples:

Run command inside of VM

```
  ./mdbci sudo --command "tail /var/log/anaconda.syslog" T/node0 --silent
  ./mdbci ssh --command "cat anaconda.syslog" T/node0 --silent
  ./mdbci setup_repo --product maxscale T/node0
  ./mdbci setup_repo --product mariadb --product-version 10.0 T/node0
  ./mdbci install_product --product 'maxscale' T/node0
  ./mdbci validate_template --template TEMPLATE_PATH
  ./mdbci show network_config T
  ./mdbci show network_config T/node0
```

Show repos with using alternative repo.d repository
```
  mdbci --repo-dir /home/testbed/config/repos show repos
```

Cloning configuration (docker_light should be launched before clonning)
```
  mdbci clone docker_light cloned_docker_light
```


## MDBCI scripts

MDBCI scripts are located in the **mdbci/scripts** directory. Their main goal is to setup and control Vagrant infrastructure.

* **./scripts/clean_vms.sh** - cleanup launched mdbci virtual machines (vbox, libvirt, docker) at the current platform. One parameter: substring
* **./scripts/run_tests.sh** - run tests that does not require virtual machines to be running. One possible named parameter for printing output: [-s true|false]
* **./scripts/install_mdbci_dependencies.sh** - install MDBCI dependencies and configure them (Debian/Ubuntu)
* **./scripts/install_mdbci_dependencies_yum.sh** - install MDBCI dependencies and configure them (CentOS)

Run script examples

```
  ./scripts/clean_vms.sh mdbci - find all VMs with ID prefix mdbci* and cleanup them.
  ./scripts/run_tests.sh -s true - run tests without output from mdbci inner methods
  ./scripts/run_tests.sh - run tests without output from mdbci inner methods
  ./scripts/run_tests.sh -s false - run tests with output from mdbci inner methods
  ./scripts/install_mdbci_dependencies.sh - install MDBCI dependencies
  ./scripts/install_mdbci_dependencies_yum.sh - install MDBCI dependencies
```



## Build parsing

This repository also contain a solution developed for parsing jenkins build logs. See https://github.com/mariadb-corporation/mdbci/tree/integration/scripts/build_parser/README.md for more details.


## Team

* Project leader: Sergey Balandin
* Developers:
  * Alexander Kaluzhniy
  * Kirill Krinkin
  * Ilfat Kinyaev
  * Mark Zaslavskiy
* Former developers:
  * Tatyana Berlenko
  * Kirill Yudenok
