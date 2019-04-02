if node[:platform] == 'linux'
  zypper_package 'ntp' do
    action :remove
  end
  zypper_package 'chrony'
else
  package 'ntp' do
    action :remove
  end
  package 'chrony'
end

service node[:chrony][:service] do
  supports restart: true, status: true, reload: true
  action %i[enable start]
end

template node[:chrony][:config_file] do
  owner 'root'
  group 'root'
  mode '0644'
  source 'chrony.conf.erb'
  notifies :restart, resources(service: node[:chrony][:service])
end

template '/usr/local/bin/synchronize_time.sh' do
  owner 'root'
  group 'root'
  mode '0755'
  source 'synchronize_time.sh.erb'
end
