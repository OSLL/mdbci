#!/bin/bash

# Add to Vagrantfile
# give name to script 'bootstrap.sh' and point shell provision
# config.vm.provision :shell, path: "bootstrap.sh"

# P.S. If MariaDB install via cookbook mdbc - NO password setup!
#      If manual MariaDB setup - you point password at install steps!

echo "Create database..."
# create database testdb
# if password set - add  -ppassword
/usr/bin/mysql -uroot -h127.0.0.1 -P3306 -e 'CREATE DATABASE testdb;'
# create testdb table
/usr/bin/mysql -uroot -h127.0.0.1 -P3306 -e 'CREATE TABLE testdb.table1 (name VARCHAR(20), rank VARCHAR(20));'
# create database testdb
/usr/bin/mysql -uroot -h127.0.0.1 -P3306 -e 'INSERT INTO testdb.table1 (name,rank) VALUES("captain","awesome");'

# copy config to /etc/mysql
sudo cp /vagrant/master/my.cnf /etc/mysql/


echo "Reload MariaDB..."
sudo service mysql restart


echo "Create replication user..."
/usr/bin/mysql -uroot -h127.0.0.1 -P3306 -e 'CREATE USER "repl"@"192.168.1.102" IDENTIFIED BY "ReplicaPass";'
echo "Grant access to replication user..."
/usr/bin/mysql -uroot -h127.0.0.1 -P3306 -e 'GRANT replication slave ON *.* TO "repl"@"192.168.1.102" IDENTIFIED BY "ReplicaPass";'
/usr/bin/mysql -uroot -h127.0.0.1 -P3306 -e 'FLUSH PRIVILEGES;'


echo "Lock database..."
# block DB ON
/usr/bin/mysql -uroot -h127.0.0.1 -P3306 -e 'USE testdb;'
/usr/bin/mysql -uroot -h127.0.0.1 -P3306 -e 'FLUSH TABLES WITH READ LOCK;'

# show master status
/usr/bin/mysql -uroot -h127.0.0.1 -P3306 -e 'SHOW MASTER STATUS\G' > master.status

echo "Create database dump..."
/usr/bin/mysqldump -uroot -h127.0.0.1 -P3306 testdb > testdb.sql
#scp -i /home/vagrant/.ssh/id_rsa.pub testdb.sql vagrant@192.168.1.102:~/
#
echo "Copy database dump to /vagrant dir for slave..."
cp testdb.sql /vagrant

echo "Copy additional file to /vagrant dir for slave machine..."
# save values File and Position for SLAVE replication from MASTER status
head master.status | grep 'File: ' | cut -f2 -d ':' > mysql_file
head master.status | grep 'Position: ' | cut -f2 -d ':' > mysql_position
# copy to slave
#scp -i /home/vagrant/.ssh/id_rsa.pub mysql_file vagrant@192.168.1.102:~/
#scp -i /home/vagrant/.ssh/id_rsa.pub mysql_position vagrant@192.168.1.102:~/
#
cp mysql_file /vagrant
cp mysql_position /vagrant


echo "Unlock database..."
/usr/bin/mysql -uroot -h127.0.0.1  -P3306 -e 'UNLOCK TABLES;'
