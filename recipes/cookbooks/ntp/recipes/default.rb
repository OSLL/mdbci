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

script "test_date" do
  interpreter "bash"
  user "root"
  environment 'platform' => node['platform']
  code <<-EOH
    sudo date --set "12 Sep 2012 12:12:12"
    echo @@@ TEST DATE: `date`
    case $platform in
    ubuntu|debian)
        sudo sntp -s 0.europe.pool.ntp.org
        ;;
    *)
        sudo service ntpd stop
        sudo ntpdate 0.europe.pool.ntp.org
        sudo service ntpd start
        ;;
    esac
    echo @@@ SYNC DATE: `date`
  EOH
end
