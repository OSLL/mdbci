name             'packages'
maintainer       'OSLL'
maintainer_email 'kirill.yudenok@gmail.com'
license          'All rights reserved'
description      'Installs packages and configure package management systems'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.1'

recipe           'install', 'Installs all required packages'
recipe           'configure_apt', 'Configures the apt to allow HTTPS-based repositories'

depends          'ntp'
