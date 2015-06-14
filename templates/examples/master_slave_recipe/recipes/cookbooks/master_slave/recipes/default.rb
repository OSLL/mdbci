#
# Cookbook Name:: master
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


# run MariaDB install with master_setup.rb recipe
include_recipe "mariadb_master_slave::master_slave_setup"
