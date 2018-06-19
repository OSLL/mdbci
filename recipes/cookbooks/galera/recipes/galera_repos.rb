# frozen_string_literal: true

include_recipe 'packages::configure_apt'

%w[net-tools psmisc].each do |pkg|
  package pkg do
    retries 2
    retry_delay 10
  end
end

case node[:platform_family]
when 'debian', 'ubuntu'
  execute 'Add repository key' do
    command "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com #{node['galera']['repo_key']}"
  end

  file '/etc/apt/sources.list.d/galera.list' do
    content "deb #{node['galera']['repo']}"
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end

  execute 'Update repository cache' do
    command 'apt-get update'
  end
when 'rhel', 'fedora', 'centos'
  template '/etc/yum.repos.d/galera.repo' do
    source 'mdbci.galera.rhel.erb'
    action :create
  end
when 'suse'
  template '/etc/zypp/repos.d/galera.repo' do
    source 'mdbci.galera.suse.erb'
    action :create
  end
end
