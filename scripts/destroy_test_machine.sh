#!/bin/bash

cur_dir=$(pwd)
cd INNER_TEST_MACHINE
vagrant destroy -f
cd ${cur_dir}

