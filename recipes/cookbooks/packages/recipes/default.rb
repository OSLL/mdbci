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
    execute "install net-tools" do
      command "apt-get -y install net-tools"
    end
  when "rhel", "fedora", "centos"
    execute "install net-tools" do
      command "yum --assumeyes install net-tools"
    end
  when "suse", "sles"
    execute "install net-tools" do
      command "zypper install -y net-tools"
    end
  else
    execute "wrong platform" do 
      echo "unknown platform"
    end
end


