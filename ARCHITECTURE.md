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

### [How to install MDBCI and dependencies](REAPARATION_FOR_MDBCI.md)

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

### [How to work with configuration files](CONFIGURATION_FILES.md)

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
