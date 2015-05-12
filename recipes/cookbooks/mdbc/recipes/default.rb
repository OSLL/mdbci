#
# Cookbook Name:: mdbc
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

#include_recipe "openssl"
#include_recipe "mysql::client"
#include_recipe "mysql::server"
#include_recipe "mysql::ruby"
#include_recipe "database"

# run MariaDB install with mdbcrepos.rb recipe
include_recipe "mariadb::install_community"
