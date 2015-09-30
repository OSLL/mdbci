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

# iptables rules
case node[:platform_family]
  when "debian", "ubuntu", "rhel", "fedora", "centos"
    bash 'Opening MariaDB ports' do
    code <<-EOF
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4567 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4568 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4444 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 3306 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4006 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4008 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4009 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4442 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 6444 -j ACCEPT
      /usr/sbin/iptables -I INPUT -m state --state RELATED,ESTABLISHED, -j ACEPT 
      /usr/sbin/iptables -I INPUT -p tcp --dport 3306 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 4006 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 4008 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 4009 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 4442 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 6444 -j ACCEPT -m state --state NEW
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
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4567 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4568 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4444 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 3306 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4006 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4008 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4009 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4442 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 6444 -j ACCEPT
      /usr/sbin/iptables -I INPUT -m state --state RELATED,ESTABLISHED, -j ACEPT 
      /usr/sbin/iptables -I INPUT -p tcp --dport 3306 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 4006 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 4008 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 4009 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 4442 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 6444 -j ACCEPT -m state --state NEW
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
