sudo apt-get install software-properties-common -y
sudo add-apt-repository ppa:openjdk-r/ppa -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt-get update
sudo apt-get install libssl-dev \
                     php5.6 \
                     perl \
                     coreutils \
                     realpath \
                     libjansson-dev \
                     openjdk-7-jdk \
                     python-pip \
                     cmake -y
                     shellcheck

sudo pip install JayDeBeApi

sudo apt-get install libmariadbclient-dev -y
sudo apt-get install libmariadb-client-lgpl-dev -y
sudo apt-get install mariadb-test -y
vagrant box add dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box
