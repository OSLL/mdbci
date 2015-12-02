include_recipe "mariadb-maxscale::maxscale_repos"

# Turn off SElinux
if node[:platform] == "centos" and node["platform_version"].to_f >= 6.0
  # TODO: centos7 don't have selinux
  bash 'Turn off SElinux on CentOS >= 6.0' do
  code <<-EOF
    selinuxenabled && flag=enabled || flag=disabled
    if [[ $flag == 'enabled' ]];
    then
      /usr/sbin/setenforce 0
    else
      echo "SElinux already disabled!"
    fi
  EOF
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
    
    ports = ["3306", "4006", "4008", "4009", "4016", "5306", "4442", "6444", "6603"]
    ports.each do |port|
      iptables_cmd = "iptables -I INPUT -p tcp -m tcp --dport "+ port +" -j ACCEPT"
      execute "Opening MariaDB-Maxscale ports." do
        command iptables_cmd
      end
    end

    execute "Opening MariaDB-Maxscale ports.." do
      command "iptables -I INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT"
    end
    
    ports.each do |port|
      iptables_cmd = "iptables -I INPUT -p tcp --dport "+ port +" -j ACCEPT -m state --state NEW"
      execute "Opening MariaDB-Maxscale ports..." do
        command iptables_cmd
      end
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
    if node[:platform] == "centos" and node["platform_version"].to_f >= 7.0
      bash 'Save iptables rules on CentOS 7' do
      code <<-EOF
        # TODO: use firewalld
        iptables-save > /etc/sysconfig/iptables
      EOF
      end
    else
      bash 'Save iptables rules on CentOS >= 6.0' do
      code <<-EOF
        /sbin/service iptables save
      EOF
      end
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
