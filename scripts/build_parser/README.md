# Maxscale build logs parsing system

## Environment setup

Install mariadb and ruby gem

<pre>
sudo apt-get install mariadb
sudo gem install mysql2
</pre>

## Db setup

Enter mysql shell:
<pre>
sudo mysql 
</pre>

Enter following commands:
<pre>
CREATE USER 'test_bot';
GRANT ALL PRIVILEGES ON test_results_db.* TO 'test_bot'@'%' IDENTIFIED BY 'YOUR_PASSWORD';
GRANT ALL PRIVILEGES ON test_results_db.* TO 'test_bot'@'localhost' IDENTIFIED BY 'YOUR_PASSWORD';
USE mysql;
SET PASSWORD FOR 'test_bot'@'%' = PASSWORD('YOUR_PASSWORD');
SET PASSWORD FOR 'test_bot'@'localhost' = PASSWORD('YOUR_PASSWORD');
</pre>

Create db

<pre>
mysql -u test_bot -pYOUR_PASSWORD -e < ./mdbci/playground/mariadb_connection/test_results_db.sql
</pre>

Create credentials file with path 
/home/vagrant/build_parser_db_password

<pre>
[client]
user=test_bot
password=YOUR_PASSWORD
</pre>

