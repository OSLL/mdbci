# attributes/default.rb

# mariadb version
default["mysql"]["version"] = "mysql-5.6"
#default["mariadb"]["version"] = [ "5.5", "10.0" ]

# mariadb repo ubuntu/debian/mint
#default["mysql"]["repo_key"] = "5072E1F5"
default["mysql"]["repo"] = "http://repo.mysql.com/apt"

# mariadb repo key for rhel/fedora/centos/suse
#default["mysql"]["repo_key"] = "http://repo.mysql.com/"
