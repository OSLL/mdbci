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

### Installation

[How to install MDBCI and dependencies](REAPARATION_FOR_MDBCI.md)


#### Install boxes locally

Usually vagrant boxes are available remotely and they are being download at the first run of vagrant up. MDBCI uses only checked boxes and they should be downloaded before first start. **Note:** in the next version of MDBCI this step will be run automatically.

<pre>
  ./mdbci setup boxes
</pre>

Known boxes could be displayed by 

<pre>
  ./mdbci show boxes
</pre>

### Workflow

Currently, we use vagrant commands for running/destroing virtual machines. In Future releases it will be shadowed by mdbci.

There are next steps for managing testing configuration:
  * Boxes and repos preparation
  * Creating stand template
  * Running up virtual machine cluster
  * Running tests
  * [Cloning configuration]
  * Destroing allocated resources
  
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
