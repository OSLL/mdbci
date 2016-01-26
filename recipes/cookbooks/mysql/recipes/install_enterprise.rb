include_recipe "mysql::mdberepos"

# Turn off SElinux
if node[:platform] == "centos" and node["platform_version"].to_f >= 6.0
  # TODO: centos7 don't have selinux
  bash 'Turn off SElinux on CentOS >= 6.0' do
    code <<-EOF
    selinuxenabled && flag=enabled || flag=disabled
    if [[ $flag == 'enabled' ]];
    then
      /usr/sbin/setenforce 0
    else
      echo "SElinux already disabled!"
    fi
    EOF
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
    command "zypper -n install --from mysql mysql-community-client mysql-community-server"
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

# Starts service
case node[:platform_family]
when "windows"
else
  service "mysql" do
    action :start
  end 
end

# node cnf_template configuration
case node[:platform_family]

  when "debian", "ubuntu"

    createcmd = "mkdir /etc/mysql/my.cnf.d"
    execute "Create cnf_template directory" do
      command createcmd
    end

    copycmd = 'cp /home/vagrant/cnf_templates/' + node['mysql']['cnf_template'] + ' /etc/mysql/my.cnf.d/'
    execute "Copy server.cnf to cnf_template directory" do
      command copycmd
    end

    # /etc/mysql/my.cnf.d -- dir for *.cnf files
    addlinecmd = 'echo -e \''+'\n'+'!includedir /etc/mysql/my.cnf.d\' | tee -a /etc/mysql/my.cnf'
    execute "Add server.cnf to my.cnf includedir parameter" do
      command addlinecmd
    end

  when "rhel", "fedora", "centos", "suse", "opensuse"

    # /etc/my.cnf.d -- dir for *.cnf files
    copycmd = 'cp /home/vagrant/cnf_templates/' + node['mysql']['cnf_template'] + ' /etc/my.cnf.d'
    execute "Copy server.cnf to cnf_template directory" do
      command copycmd
    end

    # TODO: check if line already exist !!!
    #addlinecmd = "replace '!includedir /etc/my.cnf.d' '!includedir " + node['mariadb']['cnf_template'] + "' -- /etc/my.cnf"
    addlinecmd = 'echo -e \''+'\n'+'!includedir /etc/my.cnf.d\' | tee -a /etc/my.cnf'
    execute "Add server.cnf to my.cnf !includedir parameter" do
      command addlinecmd
    end
end
