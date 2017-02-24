include_recipe "mariadb::mdberepos"
include_recipe "ntp::default"

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

system 'echo Platform family: '+node[:platform_family]

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
    execute "Opening MariaDB ports" do
      command "iptables -I INPUT -p tcp -m tcp --dport 3306 -j ACCEPT"
      command "iptables -I INPUT -p tcp --dport 3306 -j ACCEPT -m state --state NEW"
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

# copy server.cnf to my.cnf.d/ dir
case node[:platform_family]

  when "debian", "ubuntu"

    createcmd = "mkdir -p /etc/mysql/my.cnf.d/"
    execute "Create cnf_template directory" do
      command createcmd
    end

    copycmd = 'cp /home/vagrant/cnf_templates/' + node['mariadb']['cnf_template'] + ' /etc/mysql/my.cnf.d/'
    execute "Copy server.cnf to cnf_template directory" do
      command copycmd
    end

  when "rhel", "fedora", "centos", "opensuse"

    createcmd = 'mkdir -p /etc/my.cnf.d/'
    execute "Create cnf_template directory" do
      command createcmd
    end

    # /etc/my.cnf.d -- dir for *.cnf files
    copycmd = 'cp /home/vagrant/cnf_templates/' + node['mariadb']['cnf_template'] + ' /etc/my.cnf.d/'
    execute "Copy server.cnf to cnf_template directory" do
      command copycmd
    end

end


# Install packages
case node[:platform_family]
when "suse"
  execute "install" do
    command "zypper -n install --from mariadb MariaDB-server MariaDB-client"
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


# add !includedir to my.cnf
case node[:platform_family]

  when "debian", "ubuntu"

    # /etc/mysql/my.cnf.d -- dir for *.cnf files
    addlinecmd = 'echo "!includedir /etc/mysql/my.cnf.d/" >> /etc/mysql/my.cnf'
    execute "Add server.cnf dir to /etc/my.cnf includedir parameter" do
      command addlinecmd
    end

  when "rhel", "fedora", "centos", "opensuse"

    # create /etc/my.cnf file for MariaDB 5.1
    if node['mariadb']['version'] == "5.1"
      addlinecmd = 'echo -e \'#'+'\n'+'[client-server]'+'\n\n'+'# include all files from the config directory:'+'\n'+'!includedir /etc/my.cnf.d/\' >> /etc/my.cnf'
      execute "Add server.cnf dir to /etc/my.cnf includedir parameter" do
        command addlinecmd
      end
    end

end
