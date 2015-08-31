# $1 - destination directory 

dest=$1

./generate.sh community centos $dest
./generate.sh community rhel $dest
./generate.sh community sles $dest
./generate.sh community opensuse $dest
./generate.sh community debian $dest
./generate.sh community ubuntu $dest

./generate.sh community_old centos $dest
./generate.sh community_old rhel $dest

./generate.sh galera centos $dest
./generate.sh galera rhel $dest
./generate.sh galera sles $dest
./generate.sh galera opensuse $dest
./generate.sh galera debian $dest
./generate.sh galera ubuntu $dest


./generate.sh mdbe centos $dest
./generate.sh mdbe rhel $dest
./generate.sh mdbe sles $dest
./generate.sh mdbe opensuse $dest
./generate.sh mdbe debian $dest
./generate.sh mdbe ubuntu $dest

./generate.sh mysql centos $dest
./generate.sh mysql rhel $dest
./generate.sh mysql sles $dest
./generate.sh mysql debian $dest
./generate.sh mysql ubuntu $dest
