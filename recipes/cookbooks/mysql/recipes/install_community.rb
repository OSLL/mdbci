include_recipe "mysql::mdbcrepos"

# Turn off SElinux
if node[:platform] == "centos" and node["platform_version"].to_f >= 6.0 
  execute "Turn off SElinux" do
    command "setenforce 0"
  end
  cookbook_file 'selinux.config' do
    path "/etc/selinux/config"
    action :create
  end
end  # Turn off SElinux

# Install packages
case node[:platform_family]
when "suse"
  execute "install" do
    command "zypper -n install --from mysql MariaDB-server MariaDB-client &> /vagrant/log"
  end
when "debian"
  package 'mysql-server'
  package 'mysql-client'
when "windows"
  windows_package "MariaDB" do
    source "#{Chef::Config[:file_cache_path]}/mysql.msi"
    installer_type :msi
    action :install
  end
else
  package 'mysql-community-client'
  package 'mysql-community-client'
end
