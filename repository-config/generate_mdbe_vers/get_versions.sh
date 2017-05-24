lynx --dump http://downloads.mariadb.com/enterprise/WY99-BC52/mariadb-enterprise/ | grep http | grep "mariadb-" | sed "s/mariadb-/\nmariadb-/" | grep "mariadb-" | sed "s|/||" | grep -v "galera" | grep -v "tgz" | grep -v "win32" | sed "s/mariadb-enterprise//" > mariadb.versions
#lynx --dump http://downloads.mariadb.com/enterprise/WY99-BC52/mariadb-enterprise/ | grep http | grep "mariadb-" | sed "s/mariadb-/\nmariadb-/" | grep "mariadb-" | sed "s|/||" | grep "galera-" | grep -v "tgz" | grep -v "win32" | sed "s/mariadb-galera-//" > galera.versions

cp mariadb.versions ../mdbe/centos.version
cp mariadb.versions ../mdbe/rhel.version
cp mariadb.versions ../mdbe/sles.version
cp mariadb.versions ../mdbe/opensuse.version
cp mariadb.versions ../mdbe/ubuntu.version
cp mariadb.versions ../mdbe/debian.version



