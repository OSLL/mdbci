# MDBCI Installation Procedure

This directory contains scripts that install MDBCI dependencies. Currently MDBCI depends on the following components:
- [Vagrant](https://www.vagrantup.com/) is used to manage virtual images, to create and destroy created virtual machines.
- [libvirt](https://libvirt.org/) is used to directly manage created virtual machines to enable snapshot functionality and robust machine removal.
- [Amazon CLI](https://aws.amazon.com/ru/cli/) is used to directly manage created AWS virtual machines to enable snapshot functionality and robust machine removal.

The last two dependencies are only required if You want to create corresponding virtual machines.

`install.rb` script installs all the external dependencies to work with the current clone of the MDBCI. `install.sh` script first installs Ruby language interpreter and runs the `install.rb` script. The script was tested to work on Ubuntu Xenial (16.04), Ubuntu Bionic (18.04), Debian Stretch (9), Linux Mint 18.3, CentOS 6, CentOS 7, Fedora 28.
