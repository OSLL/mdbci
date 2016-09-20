#!/bin/bash

mysql --defaults-file=./scripts/db/defaults_file_dev -e 'DROP DATABASE IF EXISTS mdbci_dev_db_benchmark_parser_testing;'

