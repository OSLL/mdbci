include_recipe "galera::galera_repos"

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
  if node['galera']['version'] == "10.1"
    execute "install" do
      command "zypper -n install MariaDB-server"
    end
  else
    execute "install" do
      command "zypper -n install MariaDB-Galera-server"
    end
  end

  when "rhel", "fedora", "centos"
    system 'echo shell install on: '+node[:platform_family]
    if node['galera']['version'] == "10.1"
      execute "install" do
        command "yum --assumeyes -c /etc/yum.repos.d/galera.repo install MariaDB-server"
      end
    else
      execute "install" do
        command "yum --assumeyes -c /etc/yum.repos.d/galera.repo install MariaDB-Galera-server"
      end
    end
 
  when "debian"
    if node['galera']['version'] == "10.1"
      package 'mariadb-server'
    else
      package 'mariadb-galera-server'
    end
else
  package 'MariaDB-Galera-server'
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
