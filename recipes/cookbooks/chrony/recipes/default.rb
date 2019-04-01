package 'chrony' do
  action [:install]
end

service node['chrony']['service'][node['platform']] do
  supports restart: true, status: true, reload: true
  action %i[enable start]
end

template node['chrony']['config_file'][node['platform']] do
  owner 'root'
  group 'root'
  mode '0644'
  source 'chrony.conf.erb'
  notifies :restart, resources(service: node['chrony']['service'][node['platform']])
end
