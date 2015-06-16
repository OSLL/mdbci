# TODO
# 
# MariaDB Distribution 
#    - means that package should be installed from default linux 		distribution repository + in this case "version" can be omitted 	- just install latest version from distro repo
#
node.set["ubuntu"]["key"] = "0xcbcb082a1bb943db"
node.set["maria"]["version"] = "10.0"
node.set["maria"]["repo"] = "http://mirror.mephi.ru/mariadb/repo"
node.set["maria"]["family"] = "/"					
node.set["maria"]["repo_key"] = "http://mirror.mephi.ru/mariadb/yum"
node.set["maria"]["repo_name"] = "RPM-GPG-KEY-MariaDB"
