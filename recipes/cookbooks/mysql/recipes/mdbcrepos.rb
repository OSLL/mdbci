#
#
#
case node[:platform_family]
  when "debian", "ubuntu", "mint"
  # Add repo key
  execute "Key add" do
    command "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db"
  end
  # release_name = '$(lsb_release -cs)'
  system 'echo MySQL version: ' + node['mysql']['version']
  system 'echo MySQL repo: ' + node['mysql']['repo']
  system 'echo MySQL repo key: ' + node['mysql']['repo_key']
  system 'echo MDBCI plain repo recipe'

  # Add repo
  addrepocmd = 'echo "'+ node['mysql']['repo']+' "> /etc/apt/sources.list.d/mysql.list'
  execute "Repository add" do
    command addrepocmd
  end
  execute "update" do
    command "apt-get update"
  end

  when "rhel", "fedora", "centos"
  template "/etc/yum.repos.d/mysql.repo" do
    source "mdbci.mysql.rhel.erb"
    action :create
  end

  when "suse"
  template "/etc/zypp/repos.d/mysql.repo" do
    source "mdbci.mysql.suse.erb"
    action :create
  end

  release_name = "if cat /etc/SuSE-release | grep Enterprise &>/dev/null; then echo sles; else echo opensuse; fi"
  execute "Change suse on sles repository" do
  	command "cat /etc/zypp/repos.d/mysql.repo | sed s/suse/$(" + release_name + ")/g > /etc/zypp/repos.d/mysql.repo"
  end

end
