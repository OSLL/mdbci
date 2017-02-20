#
# Cookbook Name:: packages
# Recipe:: default
#
# Copyright 2015, OSLL <kirill.yudenok@gmail.com>
#
# All rights reserved - Do Not Redistribute
#

# TODO - move here all packages based on product (galera, maxscale)

# install additional packages for all platform
%w(net-tools psmisc).each do |pkg|
  package pkg
end


