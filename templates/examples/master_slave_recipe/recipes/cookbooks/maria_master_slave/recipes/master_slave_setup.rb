require 'shellwords'


system 'echo server-id: ' + node['mariadb']['server_id']
system 'echo database: ' + node['mariadb']['database']

#
# 1. объединить блоки
# 2. проверять какая ОСь и 
#   - отличие только /etc/mysql/my.cnf для дебиана и /etc/my.cnf для остальных
#   - и сохранение для фаервола

case node[:platform_family]
  when "debian", "ubuntu", "mint"
    
    #bash 'Install packages' do
    #code <<-EOF
    #  sudo apt-get -y install iptables-persistent
    #  EOF
    #end
	# --force-yes

    release_name = '$(lsb_release -cs)'
    system 'echo OS: ' + node[:platform_family] +' : ' + release_name
    
    # Найти my.cnf - местоположение зависит от дистрибутива Линукс
    # /etc/mysql/my.cnf

    # Config master my.cnf
    bash 'Config mariadb my.cnf' do
    code <<-EOF
      sed -i "s/bind-address/#bind-address/g" /etc/mysql/my.cnf
      sed -i "s/#server-id\t\t= 1/server-id\t\t= #{Shellwords.escape(node['mariadb']['server_id'])}/g" /etc/mysql/my.cnf
      sed -i "s/#log_bin/log_bin/g" /etc/mysql/my.cnf
      line=$(grep --line-number log_bin_index /etc/mysql/my.cnf | sed -e s/\:.*//)
      sed -i $line'ibinlog_do_db\t\t= #{Shellwords.escape(node['mariadb']['database'])}' /etc/mysql/my.cnf
      EOF
    end

    # !!!
    # ln -s /etc/apparmor.d/usr.sbin.mysqld /etc/apparmor.d/disable/   usr.sbin.mysqld; service apparmor restart'

    # сохраняются каждый раз при выполнении !!!
    bash 'Config mariadb ports' do
    code <<-EOF
      iptables -I INPUT -p tcp -m tcp --dport 3306 -j ACCEPT
      iptables -I INPUT -p tcp --dport 3306 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 4006 -j ACCEPT
      iptables -I INPUT -p tcp --dport 4006 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 4008 -j ACCEPT
      iptables -I INPUT -p tcp --dport 4008 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 4009 -j ACCEPT
      iptables -I INPUT -p tcp --dport 4009 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 4442 -j ACCEPT
      iptables -I INPUT -p tcp --dport 4442 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 6444 -j ACCEPT
      iptables -I INPUT -p tcp --dport 6444 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 5306 -j ACCEPT
      iptables -I INPUT -p tcp --dport 5306 -j ACCEPT -m state --state NEW

      iptables-save > /etc/iptables/rules.v4
      EOF
    end

    # iptables-save >/etc/firewall.conf
    # service iptables-persistent save
    # Debian/Ubuntu: iptables-save > /etc/iptables/rules.v4
    # deb - iptables-save > /etc/iptables.up.rules

  when "rhel", "fedora", "centos"

    # Config master etc/my.cnf
    bash 'Config mariadb my.cnf' do
    code <<-EOF
      sed -i 4"i#bind-address= 127.0.0.1" /etc/my.cnf
      sed -i 5"iserver-id\t\t= #{Shellwords.escape(node['mariadb']['server_id'])}" /etc/my.cnf
      sed -i 6"ilog_bin = FILENAME" /etc/my.cnf
      sed -i 6"ilog_bin_index = FILENAME" /etc/my.cnf   
      sed -i 7'ibinlog_do_db\t\t= #{Shellwords.escape(node['mariadb']['database'])}' /etc/my.cnf
      EOF
    end

    # Config master /etc/my.cnf.d/server.cnf
    bash 'Config mariadb server.cnf...' do
    code <<-EOF
      sed -i 4"ilog-basename=mar" /etc/my.cnf.d/server.cnf
      sed -i 5"iserver_id\t\t= #{Shellwords.escape(node['mariadb']['server_id'])}" /etc/my.cnf.d/server.cnf
      sed -i 6"ibinlog-format" /etc/my.cnf.d/server.cnf
      sed -i 7"ilog_bin_index=FILENAME" /etc/my.cnf.d/server.cnf
      sed -i 8"ibinlog_do_db\t\t= #{Shellwords.escape(node['mariadb']['database'])}" /etc/my.cnf.d/server.cnf
    EOF
    end

    # сохраняются каждый раз при выполнении !!!
    bash 'Config mariadb ports' do
    code <<-EOF
      iptables -I INPUT -p tcp -m tcp --dport 3306 -j ACCEPT
      iptables -I INPUT -p tcp --dport 3306 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 4006 -j ACCEPT
      iptables -I INPUT -p tcp --dport 4006 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 4008 -j ACCEPT
      iptables -I INPUT -p tcp --dport 4008 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 4009 -j ACCEPT
      iptables -I INPUT -p tcp --dport 4009 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 4442 -j ACCEPT
      iptables -I INPUT -p tcp --dport 4442 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 6444 -j ACCEPT
      iptables -I INPUT -p tcp --dport 6444 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 5306 -j ACCEPT
      iptables -I INPUT -p tcp --dport 5306 -j ACCEPT -m state --state NEW

      iptables-save > /etc/sysconfig/iptables
      service iptables save
      EOF
    end
    #RHEL/CentOS: iptables-save > /etc/sysconfig/iptables
    #RHEL/CentOS: service iptables save

  when "suse"

    # Config master etc/my.cnf
    bash 'Config mariadb my.cnf' do
    code <<-EOF
      sed -i 4"i#bind-address= 127.0.0.1" /etc/my.cnf
      sed -i 5"iserver-id\t\t= #{Shellwords.escape(node['mariadb']['server_id'])}" /etc/my.cnf
      sed -i 6"ilog_bin = FILENAME" /etc/my.cnf
      sed -i 6"ilog_bin_index = FILENAME" /etc/my.cnf   
      sed -i 7'ibinlog_do_db\t\t= #{Shellwords.escape(node['mariadb']['database'])}' /etc/my.cnf
      EOF
    end

    # Config master /etc/my.cnf.d/server.cnf
    bash 'Config mariadb server.cnf...' do
    code <<-EOF
      sed -i 4"ilog-basename=mar" /etc/my.cnf.d/server.cnf
      sed -i 5"iserver_id\t\t= #{Shellwords.escape(node['mariadb']['server_id'])}" /etc/my.cnf.d/server.cnf
      sed -i 6"ibinlog-format" /etc/my.cnf.d/server.cnf
      sed -i 7"ilog_bin_index=FILENAME" /etc/my.cnf.d/server.cnf
      sed -i 8"ibinlog_do_db\t\t= #{Shellwords.escape(node['mariadb']['database'])}" /etc/my.cnf.d/server.cnf
    EOF
    end

    # сохраняются каждый раз при выполнении !!!
    bash 'Config mariadb ports' do
    code <<-EOF
      iptables -I INPUT -p tcp -m tcp --dport 3306 -j ACCEPT
      iptables -I INPUT -p tcp --dport 3306 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 4006 -j ACCEPT
      iptables -I INPUT -p tcp --dport 4006 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 4008 -j ACCEPT
      iptables -I INPUT -p tcp --dport 4008 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 4009 -j ACCEPT
      iptables -I INPUT -p tcp --dport 4009 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 4442 -j ACCEPT
      iptables -I INPUT -p tcp --dport 4442 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 6444 -j ACCEPT
      iptables -I INPUT -p tcp --dport 6444 -j ACCEPT -m state --state NEW
      iptables -I INPUT -p tcp -m tcp --dport 5306 -j ACCEPT
      iptables -I INPUT -p tcp --dport 5306 -j ACCEPT -m state --state NEW

      iptables-save > /etc/sysconfig/iptables
      service iptables save
      EOF
    end
    # SuSeFirewall
end

bash 'Restart mysql service' do
  code "service mysql restart"
end

bash 'Create mariadb users' do
  code <<-EOF
  /usr/bin/mysql -e 'CREATE USER repl@'%'" IDENTIFIED BY 'repl';'
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

bash 'Create test database' do
  code "/usr/bin/mysql -e 'CREATE DATABASE IF NOT EXISTS test;'"
end
