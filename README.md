# MariaDB continuous integration infrastructure (MDBCI)

[MDBCI](https://github.com/mariadb-corporation/mdbci) is a set of tools for testing MariaDB components on the wide set of configurations. The main features of MDBCI are:

* automatic creation of virtual machines according to the configuration template,
* automatic and reliable deploy of MariaDB, Galera, MaxScale and other packages to the created virtual machines,
* creation and management of virtual machine state snapshots,
* reliable destruction of created virtual machines.

## Requirements

FUSE should be installed on all linux distributions as it's required to execute AppImage file.

```
sudo apt-get install -y libfuse2 fuse
```

```
sudo yum install -y fuse-libs fuse
```

* fuse-libs - additional fuse libraries for CentOS
* libfuse2 - additional fuse libraries for Ubuntu and Debian

You also may need to add current user to the `fuse` user group in case you are getting `fuse: failed to open /dev/fuse: Permission denied` error.

```
sudo addgroup fuse
usermod -a -G fuse $(whoami)
```

Check [Toubleshooting](https://docs.appimage.org/user-guide/run-appimages.html#troubleshooting) section for additional help.

## Architecture overview

MDBCI is a tool written in Ruby programming language. In order to ease the deployment of the tool the AppImage distribution is provided. It allows to use MDBCI as a standalone executable.

MDBCI uses the [Vagrant](https://www.vagrantup.com/) and a set of low-level tools to create virtual machines and reliably destroy them when the need for them is over. Currently the following Vagrant back ends are supported:

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

## MDBCI installation

MDBCI requires you to install the Libvirt in your Linux installation, install Vagrant and install required plugins.

Dependencies installation can be performed automatically using command

```
./mdbci setup-dependencies
```

This will install Libvirt development libraries, libvirt virtualization packages, vagrant and its plugins for Libvirt and AWS support, as well as all the tools required in the installation process.

Current user will be added to existing libvirt groups and a new VM pool will bew created.

During the installation you will be prompted to enter your password.

**WARNING**: upon installation previously created libvirt VM pool named 'default' will be deleted.

You can force the use of installation method for a specific Дinux distribution by passing its name to the `--force-distro` option

```
./mdbci setup-dependencies --force-distro CentOS
````

This will only work if your distribution uses the same package manager as a chosen distribution and provides all required packages.
Currently supports installation for Debian, Ubuntu, CentOS, RHEL.

To perform a clean installation call

```
./mdbci setup-dependencies --reinstall
````

This will uninstall libvirt development package, vagrant and its plugins and destroy existing 'default' libvirt pool.

If you have trouble using `./mdbci setup-dependencies` you can follow the [quickstart](docs/QUICKSTART.md) to install them manually.

## MDBCI usage

MDBCI is the command-line utility that has a lots of commands and options. A full overview of them is available from the [CLI documentation](docs/cli_help.md) or from the `mdbci` using the `--help` flag: `./mdbci --help`.

The core steps required to create virtual machines using MDBCI are:

1. Create or copy the configuration template that describes the VMs you want to create.
2. Generate concrete configuration based on the template.
3. Issue VMs creation command and wait for it's completion.
4. Use the created VMs for required purposes. You may also snapshot the VMs state and revert to it if necessary.
5. When done, call the destroy command that will terminate VMs and clear all the artifacts: configuration, template (may be kept) and network configuration file.

In the following section we will explore each step in detail. In the overview we will create two VMs: one with MariaDB database and another one with MaxScale server.

### Template creation

Template is a JSON document that describes a set of virtual machines.

```json
{
  "mariadb_host": {
    "hostname": "mariadbhost",
    "box": "centos_7_libvirt",
    "product": {
      "name": "mariadb",
      "version": "10.3",
      "cnf_template": "server1.cnf",
      "cnf_template_path": "../cnf"
    }
  },
  "maxscal_host": {
    "hostname": "maxscalehost",
    "box": "centos_7_libvirt",
    "product": {
      "name": "maxscale",
      "version": "2.3"
    }
  }
}
```

Each host description contains the `hostname` and `box` fields. The first one is set to the created virtual machine. The `box` field describes the image that is being used for VM creation and the provider. In the example we use `centos_7_libvirt` that creates the CentOS 7 using the Libvirt provider.

You can get the list of boxes using the `./mdbci show platforms` command.

Then each host is setup with the product. The products will be installed on the machines. The mandatory fields for each product is it's name and version that is required to be installed.

When installing a database you must also specify the name of the configuration file and the path to the folder where the file is stored. It is advised to use absolute path in `cnf_template_path` as the relative path is calculated from within the configuration directory.

### Configuration creation

In order to create configuration you should issue the `generate` command. Let's assume you have called the template file in the previous step `config.json`. Then the generation command might look like this:

```
./mdbci generate --template config.json config
```

After that the `config` directory containing the MDBCI configuration will be created.

During the generation procedure MDBCI will look through the repositories to find the required image and product information. Please look through the warnings to determine the issues in the template.

On this step you can safely remove the configuration directory, modify the template and regenerate the configuration once again.

### Virtual machine creation

MDBCI tries to reliably bring up the virtual machines. In order to achieve it the creation and configuration steps may be repeated several times if they fail. By default the procedure will be repeated 5 times.

It is advised to reduce this number to one as it is sufficient to catch most issues. In order to run the configuration issue the following command:

```
./mdbci up --attempts 1 config
```

### Using the virtual machines

After the successful startup the file `config_network_config` will be created. This file contains information about the network information of the created entities. You can either use this information or issue [commands directly](docs/examples.md) using special MDBCI commands.

### Shutting down the virtual machines

When finished and virtual machines are no longer needed you can issue destroy command that will:

* stop the virtual machines reliably;
* remove configuration directory;
* remove network information file;
* remove template that was used to generate the configuration.

Issue the following command:

```
mdbci destroy config
```

## Team

* Project leader: Sergey Balandin
* Developers:
  * Timofey Turenko
  * Andrey Vasilyev
  * Maksim Kosterin
  * Evgeny Vlasov
  * Roman Vlasov
* Former Developers:
  * Alexander Kaluzhniy
  * Kirill Krinkin
  * Ilfat Kinyaev
  * Mark Zaslavskiy
  * Tatyana Berlenko
  * Kirill Yudenok
