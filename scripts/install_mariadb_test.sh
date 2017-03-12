version=`lsb_release -c`

$ubuntu_codename=`echo ${version#"Codename:"}`

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

sudo apt-get install mariadb-test
