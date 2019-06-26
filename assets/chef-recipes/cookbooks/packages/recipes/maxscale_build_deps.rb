packages_list = %w[
  dpkg-dev git wget build-essential libssl-dev ncurses-dev bison flex
  perl libtool libpcre3-dev tcl tcl-dev uuid libedit-dev
  uuid-dev libsqlite3-dev liblzma-dev libpam0g-dev pkg-config
  libsystemd-dev libsystemd-daemon-dev
  libgnutls-dev libgcrypt11-dev
  libgnutls30 libgnutls-dev
  libgnutls28-dev
  libgcrypt20-dev
  libgcrypt11-dev
]
packages_list.each do |pkg|
  package pkg do
    retries 2
    retry_delay 10
    ignore_failure true
  end
end
