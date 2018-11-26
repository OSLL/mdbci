# MDBCI Examples

## Run commands inside of the virtual machines

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

Show repositories with using alternative repo.d repository
```
./mdbci --repo-dir /home/testbed/config/repos show repos
```

Cloning configuration (docker_light should be launched before clonning)
```
./mdbci clone docker_light cloned_docker_light
```
