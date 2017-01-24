sudo add-apt-repository ppa:openjdk-r/ppa -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt-get update
sudo apt-get install libssl-dev \
                     libmariadbclient-dev \
                     php5.5 \
                     perl \
                     coreutils \
                     realpath \
                     libjansson-dev \
                     openjdk-7-jdk \
                     python-pip \
                     cmake -y \
                     shellcheck
sudo pip install JayDeBeApi
