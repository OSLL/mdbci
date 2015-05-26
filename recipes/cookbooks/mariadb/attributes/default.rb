# attributes/default.rb

# mariadb version
default["maria"]["version"] = "10.0"
#default["maria"]["version"] = [ "5.5", "10.0" ]

# mariadb repo ubuntu/debian/mint
default["maria"]["repo"] = "http://mirror.mephi.ru/mariadb/repo"

# repo for centos/fedora/rhel/suse
#default["maria"]["repo"] = "http://mirror.mephi.ru/mariadb/yum"

# mariadb repo key for rhel/fedora/centos/suse
default["repo"]["key"] = "http://mirror.mephi.ru/mariadb/yum"
