# frozen_string_literal: true

# Chrony configuration file
default['chrony']['config_file'] = {
  'centos' => '/etc/chrony.conf',
  'redhat' => '/etc/chrony.conf',
  'debian' => '/etc/chrony/chrony.conf',
  'ubuntu' => '/etc/chrony/chrony.conf',
  'linux' => '/etc/chrony.conf',
  'suse' => '/etc/chrony.conf'
}

# Default configuration arrays
default['chrony']['servers'] = {
  '0.europe.pool.ntp.org' => 'offline minpoll 8'
}

# Chrony service
default['chrony']['service'] = {
  'centos' => 'chronyd',
  'redhat' => 'chronyd',
  'debian' => 'chrony',
  'ubuntu' => 'chrony',
  'linux' => 'chronyd',
  'suse' => 'chronyd'
}

# If chrony service is restarted when config file changes
default['chrony']['auto_restart'] = true
