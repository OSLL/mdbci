case node[:platform_family]
when "debian"
  package "mysql-common" do
    action :remove
  end
  execute "Remove mysql repository" do
    command "rm -fr /etc/apt/sources.list.d/mysql.list"
  end
  execute "update" do
    command "apt-get update"
  end
when "rhel", "fedora", "suse"
  package "MariaDB-common" do
    action :remove
  end
  execute "Remove repo" do
    command "rm -fr /etc/yum.repos.d/mysql.repo /etc/zypp/repos.d/mysql.repo*"
  end
end
