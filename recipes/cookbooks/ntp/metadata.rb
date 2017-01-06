name             "ntp"
maintainer       "OSLL"
maintainer_email "mdbci@osll.ru"
license          "Apache 2.0"
description      "Installs/Configures ntp"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.1"


attribute "ntp/servers",
  :display_name => "NTP Servers",
  :description => "Array of NTP servers",
  :type => "array",
  :default => ["0.pool.ntp.org", "1.pool.ntp.org", "2.pool.ntp.org", "3.pool.ntp.org" ]
