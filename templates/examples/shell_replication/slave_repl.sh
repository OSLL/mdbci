#!/bin/bash

echo "Create database..."
# if passw set - add  -ppassword after -h
/usr/bin/mysql -uroot -h127.0.0.1 -P3306 -e 'CREATE DATABASE testdb;'

echo "Import dump to database..."
/usr/bin/mysql -uroot -h127.0.0.1 -P3306 testdb < /vagrant/testdb.sql

sudo cp /vagrant/slave/my.cnf /etc/mysql/

echo "Restart MariaDB..."
sudo service mysql restart

# read File and Pos
file_=$(tail -n 1 /vagrant/mysql_file)
pos_=$(tail -n 1 /vagrant/mysql_position)
file=${file_// /}
pos=${pos_// /}

echo "Start replication..."
/usr/bin/mysql -uroot -h127.0.0.1 -P3306 -e 'CHANGE MASTER TO MASTER_HOST = "192.168.1.101", MASTER_USER = "repl", MASTER_PASSWORD = "ReplicaPass", MASTER_LOG_FILE = "'$file'", MASTER_LOG_POS = '$pos';'
#
echo "Start SLAVE..."
/usr/bin/mysql -uroot -h127.0.0.1 -P3306 -e 'START SLAVE;'

echo "Show SLAVE status..."
# SLAVE STATUS
/usr/bin/mysql -uroot -h127.0.0.1 -P3306 -e 'SHOW SLAVE STATUS\G'
