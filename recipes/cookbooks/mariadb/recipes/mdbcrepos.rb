#
#node.set_unless['maria']['version'] = "10.0"
#node.default['maria']['version'] = "10.0"
#node.override["key"] = "value"
#
case node[:platform_family]
  when "debian", "ubuntu", "mint"
  # Add repo key
  execute "Key add" do
    command "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db"
  end
  release_name = '$(lsb_release -cs)'
  system 'echo MariaDB version: ' + node['maria']['version']
  system 'echo MariaDB repo: ' + node['maria']['repo']
  system 'echo MariaDB repo key: ' + node['maria']['repo_key']
  # Add repo
  execute "Repository add" do
    command 'echo "deb ' + node['maria']['repo'] + '/' + node['maria']['version'] + '/' + node[:platform] + ' ' + release_name + ' main" > /etc/apt/sources.list.d/mariadb.list'
  end
  execute "update" do
    command "apt-get update"
  end
  when "rhel", "fedora", "centos"
  # Add the repo
  template "/etc/yum.repos.d/mariadb.repo" do
    source "mariadb.rhel.erb"
    action :create
  end
  when "suse", "sles"
  # Add the repo
  template "/etc/zypp/repos.d/mariadb.repo.template" do
    source "mariadb.suse.erb"
    action :create
  end
  release_name = "test -f /etc/os-release && cat /etc/os-release | grep '^ID=' | sed s/'^ID='//g | sed s/'\"'//g || if cat /etc/SuSE-release | grep Enterprise &>/dev/null; then echo sles; else echo opensuse; fi"
  execute "Change suse on sles repository" do
    command "cat /etc/zypp/repos.d/mariadb.repo.template | sed s/PLATFORM/$(" + release_name + ")/g > /etc/zypp/repos.d/mariadb.repo"
  end

end
