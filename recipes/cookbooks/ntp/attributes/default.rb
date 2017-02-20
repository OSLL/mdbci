case platform
when "ubuntu","debian"
  default[:ntp][:service] = "ntp"
  default[:ntp][:root_group] = "root"
when "redhat","centos","fedora"
  default[:ntp][:service] = "ntpd"
  default[:ntp][:root_group] = "root"
when "freebsd"
  default[:ntp][:service] = "ntpd"
  default[:ntp][:root_group] = "wheel"
else
  default[:ntp][:service] = "ntpd"
  default[:ntp][:root_group] = "root"
end


default[:ntp][:servers] = ["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org", "3.pool.ntp.org"]

