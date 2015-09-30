include_recipe "mariadb::mdbcrepos"

# BUG: #6309 Check if SElinux already disabled!
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

# iptables rules
case node[:platform_family]
  when "debian", "ubuntu", "rhel", "fedora", "centos"
    bash 'Opening MariaDB ports' do
    code <<-EOF
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 3306 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp --dport 3306 -j ACCEPT -m state --state NEW
    EOF
    end
  when "suse"
    execute "Install iptables and SuSEfirewall2" do
      command "zypper install -y iptables"
      command "zypper install -y SuSEfirewall2"
    end
    #
    bash 'Opening MariaDB ports' do
    code <<-EOF
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 3306 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp --dport 3306 -j ACCEPT -m state --state NEW
    EOF
   end
end # iptables rules

# TODO: check saving iptables rules
# save iptables rules
case node[:platform_family]
  when "debian", "ubuntu"
    bash 'Save MariaDB iptables rules' do
    code <<-EOF
      iptables-save > /etc/iptables/rules.v4
    EOF
    end
  when "rhel", "fedora", "centos"
    bash 'Save MariaDB iptables rules' do
    code <<-EOF
      service iptables save
    EOF
    end
    # service iptables restart
  when "suse"
    bash 'Save MariaDB iptables rules' do
    code <<-EOF
      iptables-save > /etc/sysconfig/iptables
    EOF
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
