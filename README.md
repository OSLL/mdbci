MDBC CI CLI

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





  

