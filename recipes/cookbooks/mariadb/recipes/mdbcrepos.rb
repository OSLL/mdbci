# frozen_string_literal: true

include_recipe 'packages::configure_apt'

# Install default packages
%w[net-tools psmisc].each do |pkg|
  package pkg do
    retries 2
    retry_delay 10
  end
end

# Configure repository
case node[:platform_family]
when 'debian', 'ubuntu', 'mint'
  # Add repo key
  execute 'Key add' do
    command "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com #{node['mariadb']['repo_key']}"
  end

  file '/etc/apt/sources.list.d/mariadb.list' do
    content "deb #{node['mariadb']['repo']}"
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end

  execute 'Update repository cache' do
    command 'apt-get update'
  end

when 'rhel', 'fedora', 'centos'
  template '/etc/yum.repos.d/mariadb.repo' do
    source 'mdbci.mariadb.rhel.erb'
    action :create
  end

when 'suse'
  template '/etc/zypp/repos.d/mariadb.repo' do
    source 'mdbci.mariadb.suse.erb'
    action :create
  end

  release_name = 'if cat /etc/SuSE-release | grep Enterprise &>/dev/null; then echo sles; else echo opensuse; fi'
  execute 'Change suse on sles repository' do
    command "cat /etc/zypp/repos.d/mariadb.repo | sed s/suse/$(#{release_name})/g > /etc/zypp/repos.d/mariadb.repo"
  end
end
