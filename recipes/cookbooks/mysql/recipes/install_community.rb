include_recipe "mysql::mdbcrepos"

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

# Copy server.cnf configuration file to configuration
case node[:platform_family]
when 'debian', 'ubuntu'
  db_config_dir = '/etc/mysql/my.cnf.d/'
  db_base_config = '/etc/mysql/my.cnf'
when 'rhel', 'fedora', 'centos', 'suse', 'opensuse'
  db_config_dir = '/etc/my.cnf.d/'
  db_base_config = '/etc/my.cnf'
end

directory db_config_dir do
  owner 'root'
  group 'root'
  recursive true
  mode '0755'
  action :create
end

execute 'Copy server.cnf to cnf_template directory' do
  command "cp /home/vagrant/cnf_templates/#{node['mysql']['cnf_template']} #{db_config_dir}"
end

file "#{db_config_dir}/#{node['mysql']['cnf_template']}" do
  owner 'root'
  group 'root'
  mode '0600'
end

execute 'Add my.cnf.d directory to the base mysql configuration file' do
  command "echo '\n!includedir #{db_config_dir}' >> #{db_base_config}"
end
