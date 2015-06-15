#
#
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
  template "/etc/yum.repos.d/mariadb.repo" do
    source "mariadb.rhel.erb"
    action :create
  end
  when "suse"
  template "/etc/zypp/repos.d/mariadb.repo" do
    source "mariadb.suse.erb"
    action :create
  end
  release_name = "if cat /etc/SuSE-release | grep Enterprise &>/dev/null; then echo sles; else echo opensuse; fi"
  execute "Change suse on sles repository" do
  	command "cat /etc/zypp/repos.d/mariadb.repo | sed s/suse/$(" + release_name + ")/g > /etc/zypp/repos.d/mariadb.repo"
  end

end
