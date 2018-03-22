include_recipe 'packages::configure_apt'

#
# Default packages
#
["net-tools", "psmisc"].each do |pkg|
  package pkg do
    retries 2
    retry_delay 10
  end
end
#
# MariaDB Galera repos
#
case node[:platform_family]
  #
  when "debian", "ubuntu"
  # maxscale attributes
  system 'echo Galera version: ' + node['galera']['version']
  system 'echo Galera repo: ' + node['galera']['repo']
  system 'echo Galera repo key: ' + node['galera']['repo_key']
  # Add repo key
  execute "Key add" do
    command "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com " + node['galera']['repo_key']
  end
  #release_name = '$(lsb_release -cs)'
  #system 'echo Platform: $release_name'

  repo = node['galera']['repo']
  addrepocmd = 'echo "deb '+ repo +' " >/etc/apt/sources.list.d/galera.list'

  execute "Repository add" do
    command addrepocmd
  end

  execute "update" do
    command "apt-get update"
  end

  when "rhel", "fedora", "centos"

  # Add the repo
  template "/etc/yum.repos.d/galera.repo" do
    source "mdbci.galera.rhel.erb"
    action :create
  end
  when "suse"
  # Add the repo
  template "/etc/zypp/repos.d/galera.repo" do
    source "mdbci.galera.suse.erb"
    action :create
  end
end
