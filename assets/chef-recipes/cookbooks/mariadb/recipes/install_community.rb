require 'shellwords'

include_recipe "mariadb::mdbcrepos"
include_recipe "chrony::default"

system 'echo Platform family: '+node[:platform_family]
system 'echo Platform version: '+node[:platform_version]

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

# Remove mysql-libs for MariaDB-Server 5.1
if node['mariadb']['version'] == "5.1"
  execute "Remove mysql-libs for MariaDB-Server 5.1" do
    case node[:platform]
      when "ubuntu", "debian"
        break if node[:platform_version] == "14.04"
        command "apt-get -y remove mysql-libs"
      when "rhel", "centos"
        command "yum remove -y mysql-libs"
    end
  end
end

# check and install iptables
case node[:platform_family]
  when "debian", "ubuntu"
    execute "Install iptables-persistent" do
      command "DEBIAN_FRONTEND=noninteractive apt-get -y install iptables-persistent"
    end
  when "rhel", "fedora", "centos"
    if node[:platform] == "centos" and node["platform_version"].to_f >= 7.0
      bash 'Install and configure iptables' do
      code <<-EOF
        yum --assumeyes install iptables-services
        systemctl start iptables
        systemctl enable iptables
      EOF
      end
    else
      bash 'Configure iptables' do
      code <<-EOF
        /sbin/service start iptables
        chkconfig iptables on
      EOF
      end
    end
  when "suse"
    execute "Install iptables and SuSEfirewall2" do
      command "zypper install -y iptables"
      command "zypper install -y SuSEfirewall2"
    end
end

# iptables rules
case node[:platform_family]
  when "debian", "ubuntu", "rhel", "fedora", "centos", "suse"
    execute "Opening MariaDB ports" do
      command "iptables -I INPUT -p tcp -m tcp --dport 3306 -j ACCEPT"
      command "iptables -I INPUT -p tcp --dport 3306 -j ACCEPT -m state --state NEW"
    end
end # iptables rules

# TODO: check saving iptables rules after reboot
# save iptables rules
case node[:platform_family]
  when "debian", "ubuntu"
    execute "Save MariaDB iptables rules" do
      command "iptables-save > /etc/iptables/rules.v4"
      #command "/usr/sbin/service iptables-persistent save"
    end
  when "rhel", "centos", "fedora"
    if node[:platform] == "centos" and node["platform_version"].to_f >= 7.0
      bash 'Save iptables rules on CentOS 7' do
      code <<-EOF
        iptables-save > /etc/sysconfig/iptables
      EOF
      end
    else
      bash 'Save iptables rules on CentOS >= 6.0' do
      code <<-EOF
        /sbin/service iptables save
      EOF
      end
    end
    # TODO: don't work centos7 docker
    #execute "Save MariaDB iptables rules" do
    #  command "service iptables save"
    #end
    # service iptables restart
  when "suse"
    execute "Save MariaDB iptables rules" do
      command "iptables-save > /etc/sysconfig/iptables"
    end
end # save iptables rules

# Install packages
case node[:platform_family]
when "suse"
  execute "install" do
    command "zypper -n install --from mariadb MariaDB-server MariaDB-client"
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
when "rhel", "centos"
  package 'MariaDB-server' do
    flush_cache [:before]
  end
  package 'MariaDB-client'
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
  command "cp /home/vagrant/cnf_templates/#{node['mariadb']['cnf_template']} #{db_config_dir}"
end

file "#{db_config_dir}/#{node['mariadb']['cnf_template']}" do
  owner 'root'
  group 'root'
  mode '0644'
end

if node['mariadb']['version'] == '5.1'
  execute 'Add my.cnf.d directory for old MySQL version' do
    command <<-COMMAND
    echo "\n[client-server]\n!includedir #{db_config_dir}" >> #{db_base_config}
COMMAND
  end
else
  execute 'Add my.cnf.d directory to the base mysql configuration file' do
    command "echo '\n!includedir #{db_config_dir}' >> #{db_base_config}"
  end
end
