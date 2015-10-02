require 'shellwords'

include_recipe "galera::galera_repos"

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


system 'echo Platform family: '+node[:platform_family]

# Install packages
case node[:platform_family]
  when "suse"
  if node['galera']['version'] == "10.1"
    execute "install" do
      command "zypper -n install MariaDB-server"
    end
  else
    execute "install" do
      command "zypper -n install MariaDB-Galera-server"
    end
  end

  when "rhel", "fedora", "centos"
    system 'echo shell install on: '+node[:platform_family]
    if node['galera']['version'] == "10.1"
      execute "install" do
        command "yum --assumeyes -c /etc/yum.repos.d/galera.repo install MariaDB-server"
      end
    else
      execute "install" do
        command "yum --assumeyes -c /etc/yum.repos.d/galera.repo install MariaDB-Galera-server"
      end
    end
 
  when "debian"
    if node['galera']['version'] == "10.1"
      package 'mariadb-server'
    else
      package 'mariadb-galera-server'
    end
else
  package 'MariaDB-Galera-server'
end

# Config /etc/my.cnf and /etc/mysql/my.cnf.d/server.cnf files
case node[:platform_family]
  when "debian", "ubuntu"

    bash 'Config mariadb /etc/mysql/my.cnf file' do
    code <<-EOF
      sed -i "s/bind-address/#bind-address/g" /etc/mysql/my.cnf
      sed -i 's/#server-id\t\t= 1/server-id\t\t= #{Shellwords.escape(node['galera']['server_id'])}/g' /etc/mysql/my.cnf
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
      sed -i 13"iserver-id = #{Shellwords.escape(node['galera']['server_id'])}" /etc/my.cnf.d/server.cnf
      EOF
    end

end # server.cnf block
