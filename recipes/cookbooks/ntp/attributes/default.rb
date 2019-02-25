case node['platform']
when "ubuntu","debian"
  default[:ntp][:service] = "ntp"
  default[:ntp][:root_group] = "root"
when "redhat","centos","fedora"
  default[:ntp][:service] = "ntpd"
  default[:ntp][:root_group] = "root"
  platform_version = node['platform_version'].split('.').first
  if %w(6 7).include?(platform_version)
    default[:centos_repo_baseurl] = "http://ftp.heanet.ie/pub/centos/#{platform_version}/os/x86_64/"
    default[:centos_repo_gpgkey] = "http://ftp.heanet.ie/pub/centos/#{platform_version}/os/x86_64/RPM-GPG-KEY-CentOS-#{platform_version}"
  end
when "freebsd"
  default[:ntp][:service] = "ntpd"
  default[:ntp][:root_group] = "wheel"
else
  default[:ntp][:service] = "ntpd"
  default[:ntp][:root_group] = "root"
end

default[:ntp][:servers] = ["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org", "3.pool.ntp.org"]
