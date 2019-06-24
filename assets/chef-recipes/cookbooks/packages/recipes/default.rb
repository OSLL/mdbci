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

include_recipe 'chrony::default'
