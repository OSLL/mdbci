include_recipe 'packages::configure_apt'

#
# Default packages
#
[ "net-tools", "psmisc" ].each do |pkg|
  package pkg do
    retries 2
    retry_delay 10
  end
end
#
#
#
case node[:platform_family]
  when "debian", "ubuntu", "mint"
  release_name = '$(lsb_release -cs)'
  system "echo MariaDB version: #{node['mariadb']['version']}"
  system "echo MariaDB repo: #{node['mariadb']['repo']}"
  system "echo MariaDB repo key: #{node['mariadb']['repo_key']}"
  system 'echo MDBCI plain repo recipe'

  # Add repo key
  execute "Key add" do
    command "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com #{node['mariadb']['repo_key']}"
  end

  #6373 to be removed command 'echo "deb ' + node['mariadb']['repo'] + '/' + node['mariadb']['version'] + '/' + node[:platform] + ' ' + release_name + ' main" > /etc/apt/sources.list.d/mariadb.list'
  addrepocmd = "echo 'deb #{node['mariadb']['repo']}' > /etc/apt/sources.list.d/mariadb.list"

  # Add repo
  execute "Repository add" do
    command addrepocmd
  end
  execute "update" do
    command "apt-get update"
  end

  when "rhel", "fedora", "centos"
  template "/etc/yum.repos.d/mariadb.repo" do
    source "mdbci.mariadb.rhel.erb"
    action :create
  end

  when "suse"
  template "/etc/zypp/repos.d/mariadb.repo" do
    source "mdbci.mariadb.suse.erb"
    action :create
  end

  release_name = "if cat /etc/SuSE-release | grep Enterprise &>/dev/null; then echo sles; else echo opensuse; fi"
  execute "Change suse on sles repository" do
    command "cat /etc/zypp/repos.d/mariadb.repo | sed s/suse/$(#{release_name})/g > /etc/zypp/repos.d/mariadb.repo"
  end
end
