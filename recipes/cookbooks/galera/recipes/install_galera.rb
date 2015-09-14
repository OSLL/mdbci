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
  execute "install" do
    command "zypper -n install MariaDb-Galera-server"
  end

  when "rhel", "fedora", "centos"
    system 'echo shell install on: '+node[:platform_family]
    execute "install" do
      command "yum --assumeyes -c /etc/yum.repos.d/galera.repo install MariaDB-Galera-server"
    end

  when "debian"
  package 'mariadb-galera-server'
else
  package 'MariaDB-Galera-server'
end
