#
# Cookbook Name:: packages
# Recipe:: default
#
# Copyright 2015, OSLL <kirill.yudenok@gmail.com>
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'packages::configure_apt'

# install additional packages for all platform
%w(net-tools psmisc curl).each do |pkg|
  if node[:platform] == "linux"
    zypper_package pkg do
      retries 2
      retry_delay 10
    end
  else
    package pkg do
      retries 2
      retry_delay 10
    end
  end
end

platform_is_bionic = node['platform'] == 'ubuntu' && node['platform_version'].to_i == 18
include_recipe 'packages::maxscale_build_deps' if platform_is_bionic

include_recipe 'packages::setup_resolved'
include_recipe 'chrony::default'
