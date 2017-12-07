# frozen_string_literal: true

#
# Cookbook:: mdbci_provision_mark
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# Create a directory for mdbci files
directory '/var/mdbci' do
  mode '0755'
  owner 'root'
  group 'root'
end

# Put the mark that machine has been provisioned
template '/var/mdbci/provisioned' do
  source 'provisioned.erb'
  mode '0444'
  owner 'root'
  group 'root'
  variables provisioned_time: node['ohai_time']
end
