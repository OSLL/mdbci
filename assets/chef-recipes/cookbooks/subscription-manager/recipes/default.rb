execute 'Register the system' do
  sensitive true
  command 'subscription-manager register '\
          "--username #{node['subscription-manager']['username']} "\
          "--password #{node['subscription-manager']['password']} "\
	        "--force"
  returns [0, 70]
end

execute 'Setting a Service Level Preference' do
  command 'subscription-manager service-level --set=self-support'
  returns [0, 70]
end

execute 'Attach a subscription' do
  command 'subscription-manager attach --auto'
  returns [0, 70]
end

execute 'Enable available repositories' do
  command 'subscription-manager repos --enable=*'
  returns [0, 70]
end
