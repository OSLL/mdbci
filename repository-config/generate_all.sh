# $1 - destination directory 

dest=$1

~/mdbci/repository-config/generate.sh community centos $dest
~/mdbci/repository-config/generate.sh community rhel $dest
~/mdbci/repository-config/generate.sh community sles $dest
~/mdbci/repository-config/generate.sh community opensuse $dest
~/mdbci/repository-config/generate.sh community debian $dest
~/mdbci/repository-config/generate.sh community ubuntu $dest

~/mdbci/repository-config/generate.sh community_old centos $dest
~/mdbci/repository-config/generate.sh community_old rhel $dest

~/mdbci/repository-config/generate.sh galera centos $dest
~/mdbci/repository-config/generate.sh galera rhel $dest
~/mdbci/repository-config/generate.sh galera sles $dest
~/mdbci/repository-config/generate.sh galera opensuse $dest
~/mdbci/repository-config/generate.sh galera debian $dest
~/mdbci/repository-config/generate.sh galera ubuntu $dest


~/mdbci/repository-config/generate.sh mdbe centos $dest
~/mdbci/repository-config/generate.sh mdbe rhel $dest
~/mdbci/repository-config/generate.sh mdbe sles $dest
~/mdbci/repository-config/generate.sh mdbe opensuse $dest
~/mdbci/repository-config/generate.sh mdbe debian $dest
~/mdbci/repository-config/generate.sh mdbe ubuntu $dest

~/mdbci/repository-config/generate.sh mysql centos $dest
~/mdbci/repository-config/generate.sh mysql rhel $dest
~/mdbci/repository-config/generate.sh mysql sles $dest
~/mdbci/repository-config/generate.sh mysql debian $dest
~/mdbci/repository-config/generate.sh mysql ubuntu $dest


~/mdbci/repository-config/generate.sh community_archive_yum centos $dest
~/mdbci/repository-config/generate.sh community_archive_yum rhel $dest
~/mdbci/repository-config/generate.sh community_archive_yum sles $dest
~/mdbci/repository-config/generate.sh community_archive_yum opensuse $dest
~/mdbci/repository-config/generate.sh community_archive_yum debian $dest
~/mdbci/repository-config/generate.sh community_archive_yum ubuntu $dest

~/mdbci/repository-config/generate.sh community_archive_noyum centos $dest
~/mdbci/repository-config/generate.sh community_archive_noyum rhel $dest
~/mdbci/repository-config/generate.sh community_archive_noyum sles $dest
~/mdbci/repository-config/generate.sh community_archive_noyum opensuse $dest
~/mdbci/repository-config/generate.sh community_archive_noyum debian $dest
~/mdbci/repository-config/generate.sh community_archive_noyum ubuntu $dest

