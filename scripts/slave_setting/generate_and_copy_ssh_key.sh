# Generate and copy slave ssh key to max-tst-01

ssh-keygen -t rsa
cat .ssh/id_rsa.pub | ssh vagrant@max-tst-01.mariadb.com 'cat >> .ssh/authorized_keys' # will ask for vagrant password
