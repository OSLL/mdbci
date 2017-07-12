# MariaDb continuous integration infrastructure (MDBCI)

[MDBCI](https://github.com/OSLL/mdbci) is a standard set of tools for testing MariaDb components on the wide set of configurations. The main features of **mdbci** are:

* automatic creation of virtual machine set by configuration template
* automatic deploy MariaDb/Galera and other packages to VM nodes, running configuration procedures
* support MariaDb repos on all available platforms (more than 300 at the moment)

### Current version

Current version of mdbci is 0.6 (beta)

### Roadmap

Following features are under development and will be available in the next versions of **mdbci**:

* Support remote Linux systems as mdbci nodes
* Support PPC boxes
* Support qemu images (libvirt)
* Support kvm (libvirt)
* Support Docker nodes

## Architecture

This section describes MDBCI architecture, workflow and other technical details.

### Terminology

* **Box** is a description of virtual machine image template. For vagrant provider the _box_ have the same meaning; for AWS EC2 _box_ is similar to _image_. Boxes described in [boxes.json](#boxesjson) file.

* **[MDBCI](https://github.com/OSLL/mdbci)** is a standard set of tools for testing MariaDb components on the wide set of configurations.

* **[MariaDb](http://mariadb.org)** is an enhanced, drop-in replacement for MySQL. It contains several set of components which can be used in standalone configurations and in cluster based heterogenous systems. 

* **Node** is a particular instance of virtual machine of its description.

* **Product** is a description of the particular version of software which is being under control of MDBCI. Current version supports next products:
  * mariadb -- MariaDb server and client
  * maxscale -- Maxscale server and client
  * mysql -- Mysql server and client
  * galera -- Galera server and clients
  
* **Repo** is a description of package repository with particular product version. Usually, repositories are described in repo.json formar and collected in repo.d directory (see. [repo.d files](#repod-files))

* **Template** is a set of node definitions in [template.json format](#templatejson). Templates are being used for setup a teting cluster.

### Components 

MDBCI uses vagrant with set of plugins as the VM backend manager. It's written with Ruby in order to seamless integration with vagrant. Next releases will be partially converted to vagrant plugins.

### Workflow

Currently, we use vagrant commands for running/destroing virtual machines. In Future releases it will be shadowed by mdbci.

There are next steps for managing testing configuration:
  * Boxes and repos preparation
  * Creating stand template
  * Running up virtual machine cluster
  * Running tests
  * [Cloning configuration]
  * Destroing allocated resources
  
#### Environmental variables  
  
**MDBCI_VM_PATH** varibale points to the directory for virtual machines definitions.  
  
#### Creating configuration

MDBCI generates Vagrant/chef files from template. Template example is available as instance.json. You can copy this file with another name and tailor configuration for your needs. It's possible to create multi-VM stands.

Since new template is created you can generate stand structure.

<pre>
  ./mdbci --override --template mynewstand.json generate NAME
</pre>

In this example MDBCI will generate new vagrant/chef config from mynewstand.json template. It will be placed in NAME subdirectory. If name is not specified than stand will be configured in default subdirectory. Parameter --override is required to overwrite existing configuration.

*NB* Many stands could be configured by MDBCI in subdirectories. Each stand is autonomous.

### Configuration files

MDBCI configuration is placed to the next files:

* boxes.json
* repo.d directory and repo.json files
* templates
* aws-config.yml

#### boxes.json

The file boxes.json contains definitions of available boxes. His format is commented below (**NOTE** real json does not support comments, we used ## just for this documentation). 

```
{

  ## Example of VirtualBox definition
  "debian" : { ## Box name
    "provider": "virtualbox",
    "box": "https://atlas.hashicorp.com/.../virtualbox.box", ## Box URL
    "platform": "debian",
    "platform_version": "wheezy"
  },
  
  ## Example of AWS Box Definition
  "ubuntu_vivid": {
    "provider": "aws",
    "ami": "ami-b1443fc6",  ## Amazon Image ID
    "user": "ubuntu",       ## User which will be used for access to the box
    "default_instance_type": "m3.medium",  ## Amazon instance type
    "platform": "ubuntu",
    "platform_version": "vivid"
  }
}
```

##### Available options

* provider -- virtual machine provider
* box -- virtualbox image if provider is virtualbox
* ami -- AWS image if provider is Amazon
* platform  -- name of target platform
* platform_version -- name of version of platform
* user -- user which will be used to access to box
* default_instance_type -- default instance size/type if provider is amazon

#### repo.d files

Repositories for products are described in json files. Each file could contain one or more repodefinitions (fields are commented below). During the start mdbci scans repo.d directory and builds full set of available product versions.

```
[
{
   "product":           "galera",
   "version":           "5.3.10",
   "repo":              "http://yum.mariadb.org/5.3.10/centos6-amd64",
   "repo_key":          "https://yum.mariadb.org/RPM-GPG-KEY-MariaDB",
   "platform":          "centos",
   "platform_version":  6
},
{
   "product":           "galera",
   "version":           "5.3.10",
   "repo":              "http://yum.mariadb.org/5.3.10/centos7-amd64",
   "repo_key":          "https://yum.mariadb.org/RPM-GPG-KEY-MariaDB",
   "platform":          "centos",
   "platform_version":  7
}
]
```
##### Available options

* product -- product name
* version -- product version
* repo -- link to the repo
* repo_key -- link to repo key
* platform  -- name of target platform
* platform_version -- name of version of platform

#### template.json

Templates describe particular stand configuration and have json format. Usually templait contains next blocks:

  * Global config
  * Nodes definitions
  
##### Global config parameters

The are next global optional parameters

* cookbook_path -- replaces path to cookbooks.
* aws_config -- if AWS is used. It specifies [aws_config.yml](#awsconfigyml) file. **Note** If this parameter is specified, mdbci will all nodes interpret as AWS nodes.


##### Node definition

Node definition could contain next parameters:

* hostname -- name (and hostname) for VM instance
* box -- box mane according [boxes.json](#boxesjson) file
* product -- product block definition

Product block definition looks like as an example:

```
    "product" : {
      "name": "mariadb",
      "version": "10.0.20"
    }
```

For Galera product defined some additional parameters for galera server.cnf configuration, for example:

```
    "product" : {
      "name": "galera",
      "version": "10.0",
      "cnf_template" : "server1.cnf",
      "cnf_template_path" : "../cnf",
      "node_name" : "galera0"
    }
```

If you want to use non standard configuration for box/product (for instance, you need to install centos6 package with mariadb to centos7 with some particular version) you can use hard repo name link like 

```
    "product" : {
      "repo": "mariadb@10.0.20_centos6"
    }
```

Extra information about matching boxes, versions and products could be found in [corresponded section](#box-products-versions)


#### aws_config.yml

This file contains parameters which are required for access to Amazon machines. We intentionally keep ньд format to have compatibility with other tools. Next keys are available in this file

* access_key_id -- AWS access key id
* secret_access_key --  secret access key
* keypair_name	-- private key name
* security_groups -- List of amazon security groups
* region -- AWS region
* pemfile -- pem file
* user_data -- extra user parameters
* public_ip_service -- curl to aws metadata for public ip4 address
* private_ip_service -- curl to aws metadata for private ip4 address

Here is an example

```
aws:
   access_key_id : 'your_access_key_id_from_aws'
   secret_access_key : 'your_secret_access_key_from_aws'
   keypair_name	: 'your_keypair_name'
   security_groups : [ 'default', 'vagrant' ]
   region : 'eu-west-1'	
   pemfile : '../maxscale.pem' 		# your private key
   user_data : "#!/bin/bash\nsed -i -e 's/^Defaults.*requiretty/# Defaults requiretty/g' /etc/sudoers"
   public_ip_service : "curl http://169.254.169.254/latest/meta-data/public-ipv4"
   private_ip_service : "curl http://169.254.169.254/latest/meta-data/private-ipv4"
```

### Box, products, versions

MDBCI makes matching between boxes, target platforms, products and vesions by lexicographical base. If we
have a look at the output of next command

```
./mdbci show repos 
```

we can see something like this:

```
galera@5.1+debian^squeeze => [http://mirror.netinch.com/pub/mariadb/repo/5.1/debian squeeze main]
galera@5.1+debian^jessie => [http://mirror.netinch.com/pub/mariadb/repo/5.1/debian jessie main]
galera@10.0.16+rhel^5 => [http://yum.mariadb.org/10.0.16/rhel5-amd64]
```

It means that each exact product/platform version combination is encoded 

product@version+platform^platform_version

In cases, when we need to use default product version on particular platfrom this encoding will be 

```
mdbe@?+opensuse^13 => [http://downloads.mariadb.com/enterprise/WY99-BC52/mariadb-enterprise/5.5.42-pgo/opensuse/13]
```
where mdbe@? means default mariadb community version on Opensuse13 target platfrom.


### Supported VM providers

MDBCI supports next VM providers:

* VirtualBox 4.3 and upper
* Amason EC2
* Remote PPC boxes (mdbci)
* Libvirt boxes (kvm)
* Docker boxes

#### AWS nodes

Don't forget add dummy box for vagrant aws provider by following command: vagrant box add dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box

#### Libvirt nodes

Installation steps: https://github.com/pradels/vagrant-libvirt

While testing libvirt nodes, do not forget to add the current system or server user to libvirtd group and logout. If you use Jenkins, restart it to.

Currently supported boxes:

* Ubuntu 14.04 (trusty), 12.04 (precise)
* Debian 7.5
* CentOS 6.5
* CentOS 7.0

P.S. You may use vagrant-mutate plugin for converting yours vagrant boxes  (virtualbox, ...) to libvirt boxes.

#### Docker nodes

The docker provisioner can automatically install Docker, pull Docker containers, and configure certain containers to run on boot.

All Dockerfiles store in /mdbci/templates/dockerfiles directory.

Currently supported following containers:

* Ubuntu 14.04 (trusty)
* CentOS 6.7
* CentOS 7.0

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
  * Kirill Krinkin
  * Ilfat Kinyaev
  * Mark Zaslavskiy
* Former developers:
  * Tatyana Berlenko
  * Kirill Yudenok
