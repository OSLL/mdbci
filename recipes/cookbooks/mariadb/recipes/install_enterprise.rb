include_recipe "mariadb::mdberepos"

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

# Starts service
case node[:platform_family]
when "windows"
else
  service "mysql" do
    action :start
  end 
end

# cnf_template configuration
case node[:platform_family]

  when "debian", "ubuntu"
  
    # create cnf_template dir
    createcmd = "mkdir " + node['mariadb']['cnf_template']
    execute "Create cnf_template directory" do
      command createcmd
    end

    copycmd = 'cp /vagrant/mdbci_server.cnf ' + node['mariadb']['cnf_template']
    # copy to /etc/mysql/my.cnf.d/
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

    # add includedir to my.cnf file
    # TODO: check if line already exist !!!
    # centos7 - already exist!
    addlinecmd = "echo '!includedir " + node['mariadb']['cnf_template'] + "' >> /etc/my.cnf"
    execute "Add mdbci_server.cnf to my.cnf includedir parameter" do
      command addlinecmd
    end

end

