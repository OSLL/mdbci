lynx --dump http://ftp.hosteurope.de/mirror/archive.mariadb.org/ | grep http | grep "mariadb-" | sed "s/mariadb-/\nmariadb-/" | grep "mariadb-" | sed "s|/||" | grep -v "galera" | grep -v "tgz" | grep -v "win32" | sed "s/mariadb-//" > mariadb.versions
lynx --dump http://ftp.hosteurope.de/mirror/archive.mariadb.org/ | grep http | grep "mariadb-" | sed "s/mariadb-/\nmariadb-/" | grep "mariadb-" | sed "s|/||" | grep "galera-" | grep -v "tgz" | grep -v "win32" | sed "s/mariadb-galera-//" > galera.versions

#cp mariadb.versions centos.version
#cp mariadb.versions rhel.version
#cp mariadb.versions sles.version
#cp mariadb.versions opensuse.version
#cp mariadb.versions ubuntu.version
#cp mariadb.versions debian.version

rm -f mariadb.versions.yum
rm -f mariadb.versions.noyum

VERS="$(< mariadb.versions)" #names from names.txt file
for ver in $VERS; do
    link="http://ftp.hosteurope.de/mirror/archive.mariadb.org/mariadb-$ver/yum/centos6-amd64/md5sums.txt"
    wget $link > /dev/null 2> /dev/null
    if [ $? == 0 ] ; then
	echo $ver >> mariadb.versions.yum
    else
	echo $ver >> mariadb.versions.noyum
    fi
done

rm md5sums.txt*

cp mariadb.versions.yum ../community_archive_yum/centos.version
cp mariadb.versions.yum ../community_archive_yum/rhel.version
cp mariadb.versions.yum ../community_archive_yum/sles.version
cp mariadb.versions.yum ../community_archive_yum/opensuse.version
cp mariadb.versions.yum ../community_archive_yum/ubuntu.version
cp mariadb.versions.yum ../community_archive_yum/debian.version


cp mariadb.versions.noyum ../community_archive_noyum/centos.version
cp mariadb.versions.noyum ../community_archive_noyum/rhel.version
cp mariadb.versions.noyum ../community_archive_noyum/sles.version
cp mariadb.versions.noyum ../community_archive_noyum/opensuse.version
cp mariadb.versions.noyum ../community_archive_noyum/ubuntu.version
cp mariadb.versions.noyum ../community_archive_noyum/debian.version

