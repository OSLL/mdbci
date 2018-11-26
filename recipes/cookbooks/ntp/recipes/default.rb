# Cookbook Name:: ntp

if node['platform_family'] == 'debian'
  apt_update 'update' do
    action :update
  end
end

# Set timezone to Europe/Paris
case node[:platform_family]
when "debian", "ubuntu", "rhel", "fedora", "centos", "suse", "opensuse"
  execute "Set timezone to Europe/Paris" do
    command "rm -f /etc/localtime && ln -s /usr/share/Europe/Paris /etc/localtime"
  end
end

package "ntp" do
  action [:install]
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
