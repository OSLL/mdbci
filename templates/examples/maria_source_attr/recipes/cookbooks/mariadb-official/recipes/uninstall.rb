case node[:platform_family]
when "debian"
  package "mariadb-common" do
    action :remove
  end
  execute "Remove mariadb repository" do
    command "rm -fr /etc/apt/sources.list.d/mariadb.list"
  end
  execute "update" do
    command "apt-get update"
  end
when "rhel", "fedora", "suse"
  package "MariaDB-common" do
    action :remove
  end
  execute "Remove repo" do
    command "rm -fr /etc/yum.repos.d/mariadb.repo /etc/zypp/repos.d/mariadb.repo*"
  end
end
