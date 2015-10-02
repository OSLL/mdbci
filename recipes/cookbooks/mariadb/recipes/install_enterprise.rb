require 'shellwords'

include_recipe "mariadb::mdberepos"

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
    command "zypper -n install --from mariadb MariaDB-server MariaDB-client &> /vagrant/log"
  end
when "debian"
  package 'mariadb-server'
  package 'mariadb-client'
when "windows"
  windows_package "MariaDB" do
    source "#{Chef::Config[:file_cache_path]}/mariadb.msi"
    installer_type :msi
    action :install
  end
else
  package 'MariaDB-server'
  package 'MariaDB-client'
end

# Starts service
case node[:platform_family]
when "windows"
else
  service "mysql" do
    action :start
  end 
end

# Config /etc/my.cnf and /etc/mysql/my.cnf.d/server.cnf files
case node[:platform_family]
  when "debian", "ubuntu"

    bash 'Config mariadb /etc/mysql/my.cnf file' do
    code <<-EOF
      sed -i "s/bind-address/#bind-address/g" /etc/mysql/my.cnf
      sed -i 's/#server-id\t\t= 1/server-id\t\t= #{Shellwords.escape(node['mariadb']['server_id'])}/g' /etc/mysql/my.cnf
      EOF
    end

  when "rhel", "fedora", "centos", "suse"

    bash 'Config MariaDB /etc/my.cnf file' do
    code <<-EOF
      sed -i 6"i\n" /etc/my.cnf
      sed -i 7"i[mysqld]" /etc/my.cnf
      sed -i 8"i#bind-address = 127.0.0.1" /etc/my.cnf
      sed -i 9"iserver-id = #{Shellwords.escape(node['mariadb']['server_id'])}" /etc/my.cnf
    EOF
    end

    bash 'Config MariaDB /etc/my.cnf.d/server.cnf file' do
    code <<-EOF
      sed -i 13"iserver-id = #{Shellwords.escape(node['mariadb']['server_id'])}" /etc/my.cnf.d/server.cnf
      EOF
    end

end # server.cnf block
