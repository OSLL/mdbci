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
    execute "Install iptables-persistent" do
      command "DEBIAN_FRONTEND=noninteractive apt-get -y install iptables-persistent"
    end
  when "rhel", "fedora", "centos"
    if node[:platform] == "centos" and node["platform_version"].to_f >= 7.0
      bash 'Install and configure iptables' do
      code <<-EOF
        yum --assumeyes install iptables-services
        systemctl start iptables
        systemctl enable iptables
      EOF
      end
    else
      bash 'Configure iptables' do
      code <<-EOF
        /sbin/service start iptables
        chkconfig iptables on
      EOF
      end
    end
  when "suse"
    execute "Install iptables and SuSEfirewall2" do
      command "zypper install -y iptables"
      command "zypper install -y SuSEfirewall2"
    end
end

# iptables rules
case node[:platform_family]
  when "debian", "ubuntu", "rhel", "fedora", "centos", "suse"
    bash 'Opening MariaDB ports' do
    code <<-EOF
      iptables -I INPUT -p tcp -m tcp --dport 3306 -j ACCEPT
      iptables -I INPUT -p tcp -m tcp --dport 4006 -j ACCEPT
      iptables -I INPUT -p tcp -m tcp --dport 4008 -j ACCEPT
      iptables -I INPUT -p tcp -m tcp --dport 4009 -j ACCEPT
      iptables -I INPUT -p tcp -m tcp --dport 4016 -j ACCEPT
      iptables -I INPUT -p tcp -m tcp --dport 5306 -j ACCEPT
      iptables -I INPUT -p tcp -m tcp --dport 4442 -j ACCEPT
      iptables -I INPUT -p tcp -m tcp --dport 6444 -j ACCEPT
      iptables -I INPUT -m state --state RELATED,ESTABLISHED, -j ACEPT 
      iptables -I INPUT -p tcp --dport 3306 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp --dport 4006 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp --dport 4008 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp --dport 4009 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp --dport 4016 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp --dport 5306 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp --dport 4442 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp --dport 6444 -j ACCEPT -m state --state NEW
    EOF
    end
end # iptables rules

# TODO: check saving iptables rules after reboot
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
