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


