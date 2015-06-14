require 'shellwords'


system 'echo server-id: ' + node['mariadb']['server_id']
system 'echo database: ' + node['mariadb']['database']

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

    # Найти server.cnf

    # Config master server.cnf
    #bash 'Config mariadb server.cnf...' do
    #  user 'root'
    #  code <<-EOF
    #    sed -i "s/log-basename=mar/#log-basename=mar/g" /etc/mysql/server.cnf  - comment
    #    sed -i "s/server_id/server_id/g" /etc/mysql/server.cnf  # from attribute
    #    sed -i "s/binlog-format/binlog-format/g" /etc/mysql/server.cnf  - uncomment
    #    sed -i "s/#log_bin_index/log_bin_index/g" /etc/mysql/server.cnf  - uncomment
    #    sed -i "s/#binlog_do_db/binlog_do_db/g" /etc/mysql/server.cnf  - uncomment # DB name from attribute
    #  EOF
    #  not_if "echo 'WARNING: server.cnf not configured!!!'"
    #  action :run
    #end


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

    bash 'Restart mysql service' do
      code "service mysql restart"
    end

    #  -uroot -h127.0.0.1 -P3306 
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

  
  when "rhel", "fedora" # as CentOS

    # bash 'commands' do
    # end

    #RHEL/CentOS: iptables-save > /etc/sysconfig/iptables
    #RHEL/CentOS: service iptables save

  when "suse"

    # bash 'commands' do
    # end

end
