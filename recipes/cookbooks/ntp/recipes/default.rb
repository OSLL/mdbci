# Cookbook Name:: ntp

package "ntp" do	
    action [:install]
end
 
service node[:ntp][:service] do
    service_name node[:ntp][:service]         
    action [:enable,:start,:restart]                   
end

template "/etc/ntp.conf" do			
    source "ntp.conf.erb"			# defaults to templates/files/...
    owner "root" 				# set file owner
    group "root"				# set file group
    mode 0644					# set file mode
    notifies :restart, resources(:service => node[:ntp][:service])#, :delayed
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