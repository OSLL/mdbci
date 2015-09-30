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
    bash 'Install iptables and SuSEfirewall2' do
    code <<-EOF
      zypper install -y iptables
      zypper install -y SuSEfirewall2
    EOF
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

# Starts service
case node[:platform_family]
when "windows"
else
  service "mysql" do
    action :start
  end 
end
