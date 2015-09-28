# MariaDb continuous integration infrastructure (MDBCI)

[MDBCI](https://github.com/OSLL/mdbci) is a standard set of tools for testing MariaDb components on the wide set of configurations. The main features of **mdbci** are:

* automatic creation of virtual machine set by configuration template
* automatic deploy MariaDb/Galera and other packages to VM nodes, running configuration procedures
* support MariaDb repos on all available platforms (more than 300 at the moment)

### Current version

Current version of mdbci is 0.4 (beta)

### Roadmap

Following features are under development and will be available in the next versions of **mdbci**:

* Support remote Linux systems as tager nodes
* Support PPC boxes
* Support qemu images

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

All components of MDBCI is shown in the next picture

***!!!! TBD PICTURE***

### Installation

#### Install Pre-requisities

<pre>
#echo "deb http://download.virtualbox.org/virtualbox/debian trusty contrib" >> /etc/apt/sources.list
#wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
#apt-get update
#apt-get install virtualbox-4.3

#apt-get install ruby
#wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2_x86_64.deb
#dpkg -i vagrant_1.7.2_x86_64.deb
#vagrant plugin install vagrant-vbguest
</pre>

#### Install mdbci

<pre>
  git clone https://github.com/OSLL/mdbci.git
</pre>

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
  * Destroing allocated resources
  
  
  ***PICTURE***
  
  In the picture you can see what command and files are being used on each stage

#### Creating configuration

MDBCI generates Vagrant/chef files from template. Template example is available as instance.json. You can copy this file with another name and tailor configuration for your needs. It's possible to create multi-VM stands.

Since new template is created you can generate stand structure.

<pre>
  ./mdbci --override --template mynewstand.json generate NAME
</pre>

In this example MDBCI will generate new vagrant/chef config from mynewstand.json template. It will be placed in NAME subdirectory. If name is not specified than stand will be configured in default subdirectory. Parameter --override is required to overwrite existing configuration.

*NB* Many stands could be configured by MDBCI in subdirectories. Each stand is autonomous.


### Configuration files

#### boxes.json

The file boxes.json contains definitions of available boxes. His format is commented below (**NOTE** real json does not support comments, we used ## just for this documentation). 

```
{

  ## Example of VirtualBox definition
  "debian" : { ## Box name  
    "provider": "virtualbox",
    "box": "https://atlas.hashicorp.com/chef/boxes/debian-7.4/versions/1.0.0/providers/virtualbox.box",
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


#### repo.d files

#### template.json


### Supported VM providers

MDBCI supports next VM providers:

* VirtualBox 4.3 and upper
* Amason EC2
* _Remote PPC Boxes (under development)_

## MDBCI Syntax

In this section mdbci commands are described. In order to get help in runtime just call mdbci with --help flag:

<pre>
  ./mdbci --help
</pre>
  

#### Using vagrant to manage stand

Since stand is generated it can be managed with vagrant command. 

* vagrant up --provision  -- started virtual machines and run chef scripts against them
* vagrant ssh [node] getting segure shell to [node] machine
* vagrant ssh-config [node] shows ssh configuration for [node] machine
* vagrant status -- Shows the status of current stand (if it's being run in stand directory)
* vagrant global-status -- Shows the host status$ it enumerates all machines on local host
* vagrant suspend/resume -- Control the state of machine
* vagrant destroy -- Destroys machines and all linked data

More information about vagrant features could be found in [vagrant documentation](https://docs.vagrantup.com/v2/). 

## Team

* Project leader: Sergey Balandin
* Developers:
  * Kirill Krinkin
  * Kirill Yudenok
   
   



  

