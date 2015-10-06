include_recipe "mariadb::mdbcrepos"

# BUG: #6309 Check if SElinux already disabled!
# Turn off SElinux
if node[:platform] == "centos" and node["platform_version"].to_f >= 6.0
#  execute "SElinux status" do
#  	command "/usr/sbin/selinuxenabled && echo enabled || echo disabled"
#	returns [1, 0]
#  end
  execute "Turn off SElinux" do
      command "/usr/sbin/setenforce 0"
  end
  cookbook_file 'selinux.config' do
    path "/etc/selinux/config"
    action :create
  end
end  # Turn off SElinux

# Remove mysql-libs for MariaDB-Server 5.1
if node['mariadb']['version'] == "5.1"
  execute "Remove mysql-libs for MariaDB-Server 5.1" do
    if node[:platform] == "ubuntu" and node[:platform] == "debian" 
      command "apt-get -y remove mysql-libs"
    elsif node[:platform] == "centos"
      command "yum remove -y mysql-libs"
    end
  end
end

system 'echo Platform family: '+node[:platform_family]

# Install packages
case node[:platform_family]
when "suse"
  execute "install" do
    command "zypper -n install --from mariadb MariaDB-server MariaDB-client &> /vagrant/log"
  end
when "debian"
  package 'mariadb-server'
  package 'mariadb-client'
when "windows"
  windows_package "MariaDB" do
    source "#{Chef::Config[:file_cache_path]}/mariadb.msi"
    installer_type :msi
    action :install
  end
else
  package 'MariaDB-server'
  package 'MariaDB-client'
end

# cnf_template configuration
case node[:platform_family]

  when "debian", "ubuntu"
  
    createcmd = "mkdir " + node['mariadb']['cnf_template']
    execute "Create cnf_template directory" do
      command createcmd
    end

    copycmd = 'cp /vagrant/mdbci_server.cnf ' + node['mariadb']['cnf_template']
    execute "Copy mdbci_server.cnf to cnf_template directory" do
      command copycmd
    end

    # TODO: check if line already exist !!!
    # Debian: /etc/mysql/conf.d -- dir for *.cnf files
    # Ubuntu: /etc/mysql/my.cnf.d
    addlinecmd = 'echo "!includedir ' + node['mariadb']['cnf_template'] + '" >> /etc/mysql/my.cnf'
    execute "Add mdbci_server.cnf to my.cnf includedir parameter" do
      command addlinecmd
    end

  when "rhel", "fedora", "centos", "suse"

    # centos7 - /etc/my.cnf.d -- dir for *.cnf files
    copycmd = 'cp /vagrant/mdbci_server.cnf ' + node['mariadb']['cnf_template']
    execute "Copy mdbci_server.cnf to cnf_template directory" do
      command copycmd
    end

    # TODO: check if line already exist !!!
    # centos7, rhel6 - already exist!
    #addlinecmd = "echo '!includedir " + node['mariadb']['cnf_template'] + "' >> /etc/my.cnf"
    addlinecmd = "replace '!includedir /etc/my.cnf.d' '" + node['mariadb']['cnf_template'] + "' -- /etc/my.cnf"
    execute "Add mdbci_server.cnf to my.cnf includedir parameter" do
      command addlinecmd
    end

end

