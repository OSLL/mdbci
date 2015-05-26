# attributes/default.rb

# mariadb version
default["maxscale"]["version"] = "1.1.0"

# mariadb repo ubuntu/debian/mint
default["maxscale"]["repo"] = "http://jenkins.engskysql.com/repository/1.1.0-ga/mariadb-maxscale/repo"
# repo for centos/fedora/rhel/suse
#default["maxscale"]["repo"] = "http://jenkins.engskysql.com/repository/1.1.0-ga/mariadb-maxscale/yum"
# mariadb repo key for rhel/fedora/centos/suse
default["repo"]["key"] = "http://jenkins.engskysql.com/repository/1.1.0-ga/mariadb-maxscale"
