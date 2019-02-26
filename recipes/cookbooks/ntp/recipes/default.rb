# Cookbook Name:: ntp

if node['platform_family'] == 'debian'
  apt_update 'update' do
    action :update
  end
end

# Set timezone to Europe/Paris
execute "Set timezone to Europe/Paris" do
  command "rm -f /etc/localtime && ln -s /usr/share/Europe/Paris /etc/localtime"
end

if node[:platform] == "linux"
  zypper_package "ntp"
else
  package "ntp" do
    action [:install]
  end
end

# Install sntp package on the CentOS 7 and RHEL 7
if node['platform_family'] == 'rhel' && node['platform_version'].split('.').first == '7'
  if node[:platform] == 'redhat'
    yum_repository "centos" do
      description "Centos repo"
      baseurl node[:centos_repo_baseurl]
      enabled true
      gpgcheck true
      gpgkey node[:centos_repo_gpgkey]
      action :add
    end
  end

  package('sntp') { action [:install] }
end

service node[:ntp][:service] do
  service_name node[:ntp][:service]
  action [:enable,:start,:restart]
end

template "/etc/ntp.conf" do
  source "ntp.conf.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => node[:ntp][:service])
end
