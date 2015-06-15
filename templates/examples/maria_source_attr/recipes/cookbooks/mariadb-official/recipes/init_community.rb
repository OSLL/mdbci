#
# MariaDB Community version
#
node.set_unless["ubuntu"]["key"] = "0xcbcb082a1bb943db"
node.set_unless["maria"]["version"] = "10.0"
node.set_unless["maria"]["deb_repo"] = "http://mirror.netinch.com/pub/mariadb/"
node.set_unless["maria"]["other_repo"] = "https://yum.mariadb.org/"
node.set_unless["maria"]["deb_distr"] = "/repo/"
node.set_unless["maria"]["other_distr"] = "/yum/"					
node.set_unless["maria"]["deb_family"] = "/"
node.set_unless["maria"]["other_family"] = "/"
node.set_unless["maria"]["repo_key"] = "https://yum.mariadb.org/"
node.set_unless["maria"]["repo_name"] = "RPM-GPG-KEY-MariaDB"
