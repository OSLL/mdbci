# attributes/default.rb

# maxscale version
default["maxscale"]["version"] = "1.1.0"

# maxscale repo ubuntu/debian/mint
default["maxscale"]["repo"] = "http://jenkins.engskysql.com/repository/1.1.0-ga/mariadb-maxscale/repo"

# repo for centos/fedora/rhel/suse
#default["maxscale"]["repo"] = "http://jenkins.engskysql.com/repository/1.1.0-ga/mariadb-maxscale/yum"

# debian/ubuntu repo key
#default["maxscale"]["repo_key"] = "70E4618A8167EE24"

# maxscale repo key for rhel/fedora/centos/suse
default["maxscale"]["repo_key"] = "http://jenkins.engskysql.com/repository/1.1.0-ga/mariadb-maxscale"
