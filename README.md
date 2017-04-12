# MariaDb continuous integration infrastructure (MDBCI)

[MDBCI](https://github.com/OSLL/mdbci) is a standard set of tools for testing MariaDb components on the wide set of configurations. The main features of **mdbci** are:

* automatic creation of virtual machine set by configuration template
* automatic deploy MariaDb/Galera and other packages to VM nodes, running configuration procedures
* support MariaDb repos on all available platforms (more than 300 at the moment)

## [MDBCI architecture](ARCHITECTURE.md)

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

This repository also contain a solution developed for parsing jenkins build logs. See https://github.com/OSLL/mdbci/tree/integration/scripts/build_parser/README.md for more details.

## Team

* Project leader: Sergey Balandin
* Developers:
  * Alexander Kaluzhniy
  * Tatiana Berlenko
  * Ilfat Kinyaev
  * Kirill Krinkin
  * Kirill Yudenok
  * Mark Zaslavskiy
  
