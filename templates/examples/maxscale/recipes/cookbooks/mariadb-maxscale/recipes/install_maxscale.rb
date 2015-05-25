include_recipe "mariadb-maxscale::maxscale_repos"

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
    command "zypper -n install maxscale"
  end
when "debian"
  package 'maxscale'
when "windows"
  windows_package "MariaDB" do
    source "#{Chef::Config[:file_cache_path]}/maxscale.msi"
    installer_type :msi
    action :install
  end
else
  package 'maxscale'
end

# Starts service
case node[:platform_family]
when "windows"
else
  service "mysql" do
    action :start
  end 
end
