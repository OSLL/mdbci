# Installing git
sudo apt-get install git

# Cloning repositories
git clone https://github.com/OSLL/mdbci.git $HOME/mdbci
git clone https://github.com/mariadb-corporation/mdbci-boxes.git $HOME/mdbci-boxes
git clone https://github.com/build-scripts-vagrant.git $HOME/build-scripts
git clone https://github.com/mdbci-repository-config.git $HOME/mdbci-repository-config

# MDBCI boxes and keys linking
ln -s $HOME/mdbci-boxes/BOXES $HOME/mdbci/BOXES
ln -s $HOME/mdbci-boxes/KEYS $HOME/mdbci/KEYS

# Credentials for AWS and PPC
scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null vagrant@max-tst-01.mariadb.com:/home/vagrant/mdbci/aws-config.yml $HOME/mdbci
scp -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null vagrant@max-tst-01.mariadb.com:/home/vagrant/mdbci/maxscale.pem $HOME/mdbci
