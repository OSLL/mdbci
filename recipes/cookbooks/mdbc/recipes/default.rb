#
# Cookbook Name:: mdbc
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


# run MariaDB install with mdbcrepos.rb recipe
include_recipe "mariadb::environment"
include_recipe "mariadb::install_community"
