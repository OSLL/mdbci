require 'shellwords'

include_recipe "mariadb::mdbcrepos"


# TODO: BUG: #6309 Check if SElinux already disabled!
# Turn off SElinux
if node[:platform] == "centos" and node["platform_version"].to_f >= 6.0
#  execute "SElinux status" do
#  	command "/usr/sbin/selinuxenabled && echo enabled || echo disabled"
#	returns [1, 0]
#  end
  execute "Turn off SElinux" do
      command "/usr/sbin/setenforce 0"
  end
  cookbook_file 'selinux.config' do
    path "/etc/selinux/config"
    action :create
  end
end  # Turn off SElinux

# Remove mysql-libs for MariaDB-Server 5.1
if node['mariadb']['version'] == "5.1"
  execute "Remove mysql-libs for MariaDB-Server 5.1" do
    case node[:platform]
      when "ubuntu", "debian" 
        command "apt-get -y remove mysql-libs"
      when "rhel", "centos"
        command "yum remove -y mysql-libs"
    end
  end
end

# check and install iptables
case node[:platform_family]
  when "debian", "ubuntu"
    execute "Install iptables-persistent" do
      command "apt-get -y install iptables-persistent"
    end
  when "rhel", "fedora", "centos"
    bash 'Install and config iptables services' do
    code <<-EOF
      yum --assumeyes install iptables-services
      systemctl start iptables
      systemctl enable iptables
    EOF
    end
  when "suse"

end

# iptables rules
case node[:platform_family]
  when "debian", "ubuntu", "rhel", "fedora", "centos"
    execute "Opening MariaDB ports" do
      command "iptables -I INPUT -p tcp -m tcp --dport 3306 -j ACCEPT"
      command "iptables -I INPUT -p tcp --dport 3306 -j ACCEPT -m state --state NEW"
    end
  when "suse"
    execute "Install iptables and SuSEfirewall2" do
      command "zypper install -y iptables"
      command "zypper install -y SuSEfirewall2"
    end
    #
    execute "Opening MariaDB ports" do
      command "/usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 3306 -j ACCEPT"
      command "/usr/sbin/iptables -I INPUT -p tcp --dport 3306 -j ACCEPT -m state --state NEW"
   end
end # iptables rules

# TODO: check saving iptables rules
# save iptables rules
case node[:platform_family]
  when "debian", "ubuntu"
    execute "Save MariaDB iptables rules" do
      command "iptables-save > /etc/iptables/rules.v4"
      #command "/usr/sbin/service iptables-persistent save"
    end
  when "rhel", "centos", "fedora"
    execute "Save MariaDB iptables rules" do
      command "/sbin/service iptables save"
    end
    # service iptables restart
  when "suse"
    execute "Save MariaDB iptables rules" do
      command "iptables-save > /etc/sysconfig/iptables"
    end
end # save iptables rules

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

# Config /etc/mysql/my.cnf.d/server.cnf file
#case node[:platform_family]
#  when "debian", "ubuntu"

#    bash 'Config mariadb /etc/mysql/my.cnf.d/server.cnf file' do
#    code <<-EOF
#      line=$(grep --line-number [mysqld] /etc/mysql/my.cnf.d/server.cnf | sed -e s/\:.*//)
#      sed -i $line'iserver-id\t\t= #{Shellwords.escape(node['mariadb']['server_id'])}' /etc/mysql/my.cnf.d/server.cnf
#      EOF
#    end

#  when "rhel", "fedora", "centos", "suse"

#    bash 'Config mariadb /etc/my.cnf.d/server.cnf file' do
#    code <<-EOF
#      line=$(grep --line-number [mysqld] /etc/my.cnf.d/server.cnf | sed -e s/\:.*//)
#      sed -i $line+1'iserver-id\t\t= #{Shellwords.escape(node['mariadb']['server_id'])}' /etc/my.cnf.d/server.cnf
#      EOF
#    end

#end # server.cnf block
