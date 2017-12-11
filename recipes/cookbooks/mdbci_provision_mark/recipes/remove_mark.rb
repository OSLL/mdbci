# frozen_string_literal: true

#
# Cookbook:: mdbci_provision_mark
# Recipe:: remove_mark
#
# Copyright:: 2017, Andrey Vasilyev, All Rights Reserved.

file '/var/mdbci/provisioned' do
  action :delete
end
