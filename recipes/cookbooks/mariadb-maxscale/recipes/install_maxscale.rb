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

# check and install iptables
case node[:platform_family]
  when "debian", "ubuntu"

    p "iptables packages for Deb platforms ..."

  when "rhel", "fedora", "centos"

    execute "Install and config iptables services" do
      command "yum --assumeyes install iptables-services"
      command "systemctl start iptables"
      command "systemctl enable iptables"
    end

  when "suse"

    

end

# iptables rules
case node[:platform_family]
  when "debian", "ubuntu", "rhel", "fedora", "centos"
    bash 'Opening MariaDB ports' do
    code <<-EOF
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 3306 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4006 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4008 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4009 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4016 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 5306 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4442 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 6444 -j ACCEPT
      /usr/sbin/iptables -I INPUT -m state --state RELATED,ESTABLISHED, -j ACEPT 
      /usr/sbin/iptables -I INPUT -p tcp --dport 3306 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 4006 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 4008 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 4009 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 4016 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 5306 -j ACCEPT -m state --state NEW
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
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 3306 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4006 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4008 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4009 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4016 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 5306 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4442 -j ACCEPT
      /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 6444 -j ACCEPT
      /usr/sbin/iptables -I INPUT -m state --state RELATED,ESTABLISHED, -j ACEPT 
      /usr/sbin/iptables -I INPUT -p tcp --dport 3306 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 4006 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 4008 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 4009 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 4016 -j ACCEPT -m state --state NEW
      /usr/sbin/iptables -I INPUT -p tcp --dport 5306 -j ACCEPT -m state --state NEW
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
      /sbin/service iptables save
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
    command "zypper -n install maxscale"
  end
when "debian"
  package 'maxscale'
when "windows"
  windows_package "maxscale" do
    source "#{Chef::Config[:file_cache_path]}/maxscale.msi"
    installer_type :msi
    action :install
  end
else
  package 'maxscale'
end
