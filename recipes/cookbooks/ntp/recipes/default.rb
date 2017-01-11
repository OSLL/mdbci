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

system 'echo @@@ TEST DATE'
system 'sudo date --set "12 Sep 2012 12:12:12"'
system 'echo @@@ BEFORE `date`'
system 'sudo sntp -s 0.europe.pool.ntp.org'

system 'echo @@@ AFTER_1 `date`'

system 'sudo ntpdate 0.europe.pool.ntp.org'

system 'echo @@@ AFTER_2 `date`'