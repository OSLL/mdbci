#
# Remove any extra configuration from the systemd-resolved that some images have
#

RESOLVED_FILE = '/etc/systemd/resolved.conf'

if File.exist?(RESOLVED_FILE)
  cookbook_file RESOLVED_FILE do
    source 'resolved.conf'
    mode '0644'
    owner 'root'
    group 'root'
    action :create
  end

  service 'systemd-resolved' do
    action :restart
  end
end
