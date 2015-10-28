require 'shellwords'

include_recipe "mariadb::mdbcrepos"

case node[:platform_family]
  when "debian", "ubuntu", "mint"

    release_name = '$(lsb_release -cs)'
    system 'echo OS: ' + node[:platform_family] +' : ' + release_name
    
    # Config master-slave /etc/mysql/my.cnf
    bash 'Config mariadb my.cnf' do
    code <<-EOF
      sed -i "s/bind-address/#bind-address/g" /etc/mysql/my.cnf
      sed -i "s/#server-id\t\t= 1/server-id\t\t= #{Shellwords.escape(node['mariadb']['server_id'])}/g" /etc/mysql/my.cnf
      sed -i "s/#log_bin/log_bin/g" /etc/mysql/my.cnf
      line=$(grep --line-number log_bin_index /etc/mysql/my.cnf | sed -e s/\:.*//)
      sed -i $line'ibinlog_do_db\t\t= #{Shellwords.escape(node['mariadb']['database'])}' /etc/mysql/my.cnf
      EOF
    end

  when "rhel", "fedora", "centos", "suse"

    # Config master-slave /etc/my.cnf
    bash 'Config mariadb my.cnf' do
    code <<-EOF
      sed -i 6"i[mysqld]" /etc/my.cnf
      sed -i 7"i#bind-address = 127.0.0.1" /etc/my.cnf
      sed -i 8"iserver-id = #{Shellwords.escape(node['mariadb']['server_id'])}" /etc/my.cnf
      sed -i 9'ibinlog-do-db = #{Shellwords.escape(node['mariadb']['database'])}' /etc/my.cnf
      sed -i 10"irelay_log = /var/lib/mysql/mysql-relay-bin" /etc/my.cnf
      sed -i 11"irelay-log-index = /var/lib/mysql/mysql-relay-bin.index" /etc/my.cnf
      sed -i 12"ilog-error = /var/lib/mysql/mysql.err" /etc/my.cnf
      sed -i 13"imaster-info-file = /var/lib/mysql/mysql-master.info" /etc/my.cnf
      sed -i 14"irelay-log-info-file = /var/lib/mysql/mysql-relay-log.info" /etc/my.cnf
      sed -i 15"ilog-bin = /var/lib/mysql/mysql-bin" /etc/my.cnf
      EOF
    end
    # slave - replicate-do-db

    
end
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

# cnf_template configuration
case node[:platform_family]

  when "debian", "ubuntu"
  
    createcmd = "mkdir /etc/mysql/my.cnf.d"
    execute "Create cnf_template directory" do
      command createcmd
    end

    copycmd = 'cp /home/vagrant/cnf_templates/' + node['mariadb']['cnf_template'] + ' /etc/mysql/my.cnf.d'
    execute "Copy mdbci_server.cnf to cnf_template directory" do
      command copycmd
    end

    # /etc/mysql/my.cnf.d -- dir for *.cnf files
    addlinecmd = 'echo "!includedir /etc/mysql/my.cnf.d" >> /etc/mysql/my.cnf'
    execute "Add mdbci_server.cnf to my.cnf includedir parameter" do
      command addlinecmd
    end

  when "rhel", "fedora", "centos", "suse"

    # /etc/my.cnf.d -- dir for *.cnf files
    copycmd = 'cp /home/vagrant/cnf_templates/' + node['mariadb']['cnf_template'] + ' /etc/my.cnf.d'
    execute "Copy mdbci_server.cnf to cnf_template directory" do
      command copycmd
    end

    # TODO: check if line already exist !!!
    #addlinecmd = "replace '!includedir /etc/my.cnf.d' '!includedir " + node['mariadb']['cnf_template'] + "' -- /etc/my.cnf"
    #execute "Add mdbci_server.cnf to my.cnf includedir parameter" do
    #  command addlinecmd
    #end
end

# Config master-slave /etc/my.cnf.d/server.cnf
bash 'Config mariadb server.cnf' do
code <<-EOF
  sed -i 13"ilog-basename=mar" /etc/my.cnf.d/server.cnf
  sed -i 14"ilog-bin" /etc/my.cnf.d/server.cnf
  sed -i 15"ibinlog-format=STATEMENT" /etc/my.cnf.d/server.cnf
  sed -i 16"iserver_id=#{Shellwords.escape(node['mariadb']['server_id'])}" /etc/my.cnf.d/server.cnf
EOF
end

bash 'Restart mariadb service' do
  code "service mysql restart"
end
# 
bash 'Create mariadb users' do
  code <<-EOF
  /usr/bin/mysql -e 'CREATE USER repl@'%' IDENTIFIED BY 'repl';'
  /usr/bin/mysql -e 'GRANT replication slave ON *.* TO repl@'%' IDENTIFIED BY 'repl';'
  /usr/bin/mysql -e 'CREATE USER skysql@'%' IDENTIFIED BY 'skysql';'
  /usr/bin/mysql -e 'CREATE USER skysql@'localhost' IDENTIFIED BY 'skysql';'
  /usr/bin/mysql -e 'GRANT ALL PRIVILEGES ON *.* TO skysql@'%' WITH GRANT OPTION;'
  /usr/bin/mysql -e 'GRANT ALL PRIVILEGES ON *.* TO skysql@'localhost' WITH GRANT OPTION;'
  /usr/bin/mysql -e 'CREATE USER maxuser@'%' identified by 'maxpwd';'
  /usr/bin/mysql -e 'CREATE USER maxuser@'localhost' identified by 'maxpwd';'
  /usr/bin/mysql -e 'GRANT ALL PRIVILEGES ON *.* TO maxuser@'%' WITH GRANT OPTION;'
  /usr/bin/mysql -e 'GRANT ALL PRIVILEGES ON *.* TO maxuser@'localhost' WITH GRANT OPTION;'
  /usr/bin/mysql -e 'FLUSH PRIVILEGES;'
  EOF
end
#
bash 'Create test database' do
  code "/usr/bin/mysql -e 'CREATE DATABASE IF NOT EXISTS test;'"
end