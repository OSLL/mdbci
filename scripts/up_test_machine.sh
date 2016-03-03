#!/usr/bin/env bash

./mdbci --override --template spec/configs/template/centos_6_vbox_mariadb_10.0.json generate INNER_TEST_MACHINE
./mdbci up INNER_TEST_MACHINE
