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

mdb_cnf="/home/vagrant/build_parser_db_password"
scp vagrant@max-tst-01.mariadb.com:"$mdb_cnf" "$mdb_cnf"
sed -ie 's/localhost/max-tst-01.mariadb.com/g' "$mdb_cnf"

sudo apt-get install build-essential ruby ruby-dev -y libnetcdf-dev libssl-dev libcrypto++-dev libmariadbclient-dev libmariadbd-dev
sudo gem install mysql2
