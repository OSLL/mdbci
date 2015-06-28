require 'shellwords'
#
case node[:platform_family]
when "debian", "ubuntu"
  #
  execute "Key add" do
    command "gpg --recv-keys --keyserver keyserver.ubuntu.com " + node['mysql']['repo_key']
  end
  #
  system 'echo MySQL version: ' + node['mysql']['version']
  system 'echo MySQL repo: ' + node['mysql']['repo']
  system 'echo MySQL repo key: ' + node['mysql']['repo_key']
  #
  bash 'Repository add' do
    code <<-EOF
      release_name=$(lsb_release -cs)
      echo "deb #{Shellwords.escape(node['mysql']['repo'])}/#{Shellwords.escape(node[:platform])} $release_name #{Shellwords.escape(node['mysql']['version'])}" > /etc/apt/sources.list.d/mysql.list
    EOF
  end
  #execute "Repository add" do
  #  command 'echo "deb ' + node['mysql']['repo'] + '/' + node[:platform] + ' ' + release_name + ' ' + node['mysql']['version'] + ' > /etc/apt/sources.list.d/mysql.list'
  #end
  execute "update" do
    command "apt-get update"
  end
when "rhel", "fedora", "centos"
  template "/etc/yum.repos.d/mysql.repo" do
    source "mysql.rhel.erb"
    action :create
  end
when "suse"
  template "/etc/zypp/repos.d/mysql.repo" do
    source "mysql.suse.erb"
    action :create
  end
  #release_name = "if cat /etc/SuSE-release | grep Enterprise &>/dev/null; then echo sles; else echo opensuse; fi"
  #execute "Change suse on sles repository" do
  #	command "cat /etc/zypp/repos.d/mysql.repo | sed s/suse/$(" + release_name + ")/g > /etc/zypp/repos.d/mysql.repo"
  #end

end
