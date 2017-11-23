# Fetch repos (boxes, configs, MDBCI, maxscale repo with tests, load ssh keys)

# Installing git
sudo apt-get install git

# Cloning repositories
git clone https://github.com/mariadb-corporation/mdbci.git $HOME/mdbci
git clone https://github.com/mariadb-corporation/build-scripts-vagrant.git $HOME/build-scripts

# Credentials for AWS and PPC
scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null vagrant@max-tst-01.mariadb.com:/home/vagrant/mdbci/aws-config.yml $HOME/mdbci
scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null vagrant@max-tst-01.mariadb.com:/home/vagrant/mdbci/maxscale.pem $HOME/mdbci
