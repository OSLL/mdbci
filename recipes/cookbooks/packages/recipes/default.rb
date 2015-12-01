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
case node[:platform_family]
  when "debian", "ubuntu"
    # install packages for ubuntu
  when "rhel", "fedora", "centos"
    # install packages for rhel
    if node[:platform] == "centos" and node["platform_version"].to_f >= 7.0
      execute "install net-tools for centos 7.0" do
        command "yum --assumeyes install net-tools"
      end
    end
  when "suse", "sles"
    # install packages for sles
  else
    # unknown platform
end


