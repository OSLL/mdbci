include_recipe "mysql::mdbcrepos"

# Turn off SElinux
if node[:platform] == "centos" and node["platform_version"].to_f >= 6.0 
  execute "Turn off SElinux" do
    command "setenforce 0"
  end
  cookbook_file 'selinux.config' do
    path "/etc/selinux/config"
    action :create
  end
end  # Turn off SElinux

# Install packages
case node[:platform_family]
when "suse"
  execute "install" do
    command "zypper -n install --from mysql mysql-community-client mysql-community-server &> /vagrant/log"
  end
when "debian"
  package 'mysql-server'
  package 'mysql-client'
when "windows"
  windows_package "MariaDB" do
    source "#{Chef::Config[:file_cache_path]}/mysql.msi"
    installer_type :msi
    action :install
  end
else
  package 'mysql-community-client'
  package 'mysql-community-server'
end

# node cnf_template configuration
case node[:platform_family]

  when "debian", "ubuntu"

    createcmd = "mkdir /etc/mysql/my.cnf.d"
    execute "Create cnf_template directory" do
      command createcmd
    end

    copycmd = 'cp /home/vagrant/cnf_templates/' + node['mysql']['cnf_template'] + ' /etc/mysql/my.cnf.d/'
    execute "Copy mdbci_server.cnf to cnf_template directory" do
      command copycmd
    end

    # /etc/mysql/my.cnf.d -- dir for *.cnf files
    addlinecmd = 'echo "!includedir /etc/mysql/my.cnf.d" >> /etc/mysql/my.cnf'
    execute "Add mdbci_server.cnf to my.cnf includedir parameter" do
      command addlinecmd
    end

  when "rhel", "fedora", "centos", "suse", "opensuse"

    # /etc/my.cnf.d -- dir for *.cnf files
    copycmd = 'cp /home/vagrant/cnf_templates/' + node['mysql']['cnf_template'] + ' /etc/my.cnf.d'
    execute "Copy mdbci_server.cnf to cnf_template directory" do
      command copycmd
    end

  # TODO: check if line already exist !!!
  #addlinecmd = "replace '!includedir /etc/my.cnf.d' '!includedir " + node['mariadb']['cnf_template'] + "' -- /etc/my.cnf"
  #execute "Add mdbci_server.cnf to my.cnf includedir parameter" do
  #  command addlinecmd
  #end
end