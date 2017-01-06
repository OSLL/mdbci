ubuntu_codename=$(cat /etc/*release 2>/dev/null | grep "UBUNTU_CODENAME" | awk -F'=' '{print $2}')
if [[ -z "$ubuntu_codename" ]]; then
    ubuntu_codename=$(cat /etc/*release 2>/dev/null | grep "DISTRIB_CODENAME" | awk -F'=' '{print $2}')
fi

if [[ "$ubuntu_codename" == "xenial" ]]; then
        sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
elif [[ "$ubuntu_codename" == "trusty" ]]; then
        sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xcbcb082a1bb943db
fi

sudo add-apt-repository "deb [arch=amd64,i386,ppc64el] http://mirror.timeweb.ru/mariadb/repo/10.0/ubuntu $ubuntu_codename main"

echo "deb [arch=amd64,i386] http://mirror.timeweb.ru/mariadb/repo/10.0/ubuntu $ubuntu_codename main" | sudo tee /etc/apt/sources.list.d/mariadb.list
echo "deb-src http://mirror.timeweb.ru/mariadb/repo/10.0/ubuntu $ubuntu_codename main" | sudo tee --append /etc/apt/sources.list.d/mariadb.list

sudo apt-get update
sudo apt-get install software-properties-common  -y
sudo debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password_again password root'
DEBIAN_FRONTEND=noninteractive sudo apt-get install mariadb-server -y

mysql -uroot -proot -e "CREATE DATABASE test_results_db;"
mysql -uroot -proot -e "CREATE USER 'test_bot';"
mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON test_results_db.* TO 'test_bot'@'%' IDENTIFIED BY 'pass';"
mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON test_results_db.* TO 'test_bot'@'localhost' IDENTIFIED BY 'pass';"
mysql -uroot -proot -e "USE mysql;"
mysql -uroot -proot -e "SET PASSWORD FOR 'test_bot'@'%' = PASSWORD('pass');"
mysql -uroot -proot -e "SET PASSWORD FOR 'test_bot'@'localhost' = PASSWORD('pass');"

mdb_cnf="/home/vagrant/build_parser_db_password"
echo "[client]" > "$mdb_cnf"
echo "user=test_bot" >> "$mdb_cnf"
echo "password=pass" >> "$mdb_cnf"
echo "host=localhost" >> "$mdb_cnf"

wget https://raw.githubusercontent.com/OSLL/mdbci/integration/scripts/db/test_results_db.sql
mysql -utest_bot -ppass --database test_results_db < ./test_results_db.sql
rm test_results_db.sql

sudo apt-get install build-essential ruby ruby-dev -y libnetcdf-dev libssl-dev libcrypto++-dev libmariadbclient-dev libmariadbd-dev
sudo gem install mysql2