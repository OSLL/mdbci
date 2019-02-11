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

package('sntp') { action [:install] } if node['platform_family'] == 'rhel'

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
