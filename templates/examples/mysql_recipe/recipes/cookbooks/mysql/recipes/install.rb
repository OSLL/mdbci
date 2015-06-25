include_recipe "mysql::repos"

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
    command "zypper -n install mysql-server mysql-client &> /vagrant/log"
  end
when "debian"
  execute "install" do
    command "DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes mysql-server mysql-client"
  end
  #package 'mysql-server'
  #package 'mysql-client'
when "windows"
  windows_package "MySQL" do
    source "#{Chef::Config[:file_cache_path]}/mysql.msi"
    installer_type :msi
    action :install
  end
else
  package 'mysql-server'
  package 'mysql-client'
end
