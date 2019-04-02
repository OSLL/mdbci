if node[:platform] == 'linux'
  zypper_package 'chrony'
else
  package 'chrony' do
    action [:install]
  end
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

template '/usr/local/bin/synchronize_time.sh' do
  owner 'root'
  group 'root'
  mode '0755'
  source 'synchronize_time.sh.erb'
end
