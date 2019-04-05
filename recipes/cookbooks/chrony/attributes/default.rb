# frozen_string_literal: true

# Chrony configuration file
default[:chrony][:config_file] = case node[:platform]
                                 when 'ubuntu', 'debian'
                                   '/etc/chrony/chrony.conf'
                                 else
                                   '/etc/chrony.conf'
                                 end

# Default configuration arrays
default[:chrony][:servers] = {
  '0.europe.pool.ntp.org' => 'iburst minpoll 8',
  '1.europe.pool.ntp.org' => 'iburst minpoll 8',
  '2.europe.pool.ntp.org' => 'iburst minpoll 8',
  '3.europe.pool.ntp.org' => 'iburst minpoll 8'
}

# Chrony service
default[:chrony][:service] = case node[:platform]
                             when 'ubuntu', 'debian'
                               'chrony'
                             else
                               'chronyd'
                             end
