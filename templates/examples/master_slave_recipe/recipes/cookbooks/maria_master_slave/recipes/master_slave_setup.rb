require 'shellwords'


system 'echo server-id: ' + node['mariadb']['server_id']
system 'echo database: ' + node['mariadb']['database']


# MY.CNF block
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

    # Config master-slave /etc/my.cnf.d/server.cnf
    bash 'Config mariadb server.cnf' do
    code <<-EOF
      sed -i 13"ilog-basename=mar" /etc/my.cnf.d/server.cnf
      sed -i 14"ilog-bin" /etc/my.cnf.d/server.cnf
      sed -i 15"ibinlog-format=STATEMENT" /etc/my.cnf.d/server.cnf
      sed -i 16"iserver_id=#{Shellwords.escape(node['mariadb']['server_id'])}" /etc/my.cnf.d/server.cnf
    EOF
    end
end # MY.CNF block

# iptables rules
case node[:platform_family]
  when "debian", "ubuntu", "mint", "rhel", "fedora", "centos"
  
  bash 'Config mariadb iptables ports' do
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
  EOF
  end

  when "suse"

  bash 'Install iptables and SuSEfirewall2' do
  code <<-EOF
    zypper install -y iptables
    zypper install -y SuSEfirewall2
  EOF
  end

  bash 'Config mariadb iptables ports' do
  code <<-EOF
    /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 3306 -j ACCEPT
    /usr/sbin/iptables -I INPUT -p tcp --dport 3306 -j ACCEPT -m state --state NEW
    /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4006 -j ACCEPT
    /usr/sbin/iptables -I INPUT -p tcp --dport 4006 -j ACCEPT -m state --state NEW
    /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4008 -j ACCEPT
    /usr/sbin/iptables -I INPUT -p tcp --dport 4008 -j ACCEPT -m state --state NEW
    /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4009 -j ACCEPT
    /usr/sbin/iptables -I INPUT -p tcp --dport 4009 -j ACCEPT -m state --state NEW
    /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 4442 -j ACCEPT
    /usr/sbin/iptables -I INPUT -p tcp --dport 4442 -j ACCEPT -m state --state NEW
    /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 6444 -j ACCEPT
    /usr/sbin/iptables -I INPUT -p tcp --dport 6444 -j ACCEPT -m state --state NEW
    /usr/sbin/iptables -I INPUT -p tcp -m tcp --dport 5306 -j ACCEPT
    /usr/sbin/iptables -I INPUT -p tcp --dport 5306 -j ACCEPT -m state --state NEW
  EOF
  end

end # iptables rules

# Iptables block
case node[:platform_family]

  when "debian", "ubuntu", "mint"
    # сохраняются каждый раз при выполнении !!!
    bash 'Save mariadb iptables ports' do
    code <<-EOF
      iptables-save > /etc/iptables/rules.v4
    EOF
    end
    # service iptables-persistent save

  when "rhel", "fedora", "centos"
    # сохраняются каждый раз при выполнении !!!
    bash 'Save mariadb iptables ports' do
    code <<-EOF
      iptables-save > /etc/sysconfig/iptables
    EOF
    end
    # CHECK - service iptables save

  when "suse"
    # сохраняются каждый раз при выполнении !!!
    bash 'Save mariadb iptables ports' do
    code <<-EOF
      iptables-save > /etc/sysconfig/iptables
    EOF
    end
    # CHECK - save rules via SuSeFirewall2

end # Iptables block

# 
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
