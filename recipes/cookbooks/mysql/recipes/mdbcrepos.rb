include_recipe 'packages::configure_apt'

# Install default packages
%w( net-tools psmisc ).each do |pkg|
  package pkg do
    retries 2
    retry_delay 10
  end
end

# Configure repository
case node[:platform_family]
when "debian", "ubuntu", "mint"
  # Add repo key
  execute "Key add" do
    command "apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 5072E1F5"
  end

  file '/etc/apt/sources.list.d/mysql.list' do
    content node['mysql']['repo']
    owner 'root'
    group 'root'
    mode '0644'
    action :create
  end

  execute "Update repository cache" do
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
