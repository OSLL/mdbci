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
  
* **Repo** is a description of package repository with particular product version. Usually, repositories are described in repo.json formar and collected in repo.d directory (see. [repo.d files](#repod-files)

* **Template** is a set of node definitions in [template.json format](#templatejson). Templates are being used for setup a teting cluster.

### Components 

### Workflow

### Configuration files

#### boxes.json

#### repo.d files

#### template.json

### Supported VM providers

MDBCI supports next VM providers:

* VirtualBox 4.3 and upper
* Amason EC2
* _Remote PPC Boxes (under development)_

## MDBCI Syntax

For help:

  ./mdbci --help
  
## REQUIREMENTS
Add [deb http://download.virtualbox.org/virtualbox/debian trusty contrib] into /etc/apt/sources.list

wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -

<pre>
  apt-get update
  apt-get install virtualbox-4.3
</pre>

  
<pre>
  #apt-get install ruby
  
  $wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2_x86_64.deb
  #dpkg -i vagrant_1.7.2_x86_64.deb
  $vagrant plugin install vagrant-vbguest
</pre>

## WORKFLOW

#### Download last version of mdbci

<pre>
  git clone https://github.com/OSLL/mdbci.git
</pre>

#### Install boxes locally

Usually vagrant boxes are available remotely and they are being download at the first run of vagrant up. MDBCI uses only checked boxes and they should be downloaded before first start.

<pre>
  ./mdbci setup boxes
</pre>

Known boxes could be displayed by 

<pre>
  ./mdbci show boxes
</pre>


#### Create configuration

MDBCI can generate Vagrant/chef files by template. Template example is available as instance.json. You can copy this file with another name and tailor configuration for your needs. It's possible to create multi-VM stands.

Since new template is created you can generate stand structure.

<pre>
  ./mdbci --override --template mynewstand.json generate NAME
</pre>

In this example MDBCI will generate new vagrant/chef config from mynewstand.json template. It will be placed in NAME subdirectory. If name is not specified than stand will be configured in default subdirectory. Parameter --override is required to overwrite existing configuration.

*NB* Many stands could be configured by MDBCI in subdirectories. Each stand is autonomous.

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

### Team

* Project leader: Sergey Balandin
* Developers:
  * Kirill Krinkin
  * Kirill Yudenok
   
   



  

