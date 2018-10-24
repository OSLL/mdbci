# MDBCI scripts

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
