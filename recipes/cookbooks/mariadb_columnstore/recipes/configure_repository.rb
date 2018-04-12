# install default packages
[ "net-tools", "psmisc" ].each do |pkg|
  package pkg
end

# This hash is defined here only to ease testing purposes
default_repos = {
  'debian' => {
    repo: 'https://downloads.mariadb.com/ColumnStore/1.1.3/repo/debian8',
    key: 'AD0DEAFDA41F5C14'
  },
  'ubuntu' => {
    repo: 'https://downloads.mariadb.com/ColumnStore/1.1.3/repo/ubuntu16',
    key: 'AD0DEAFDA41F5C14'
  },
  'centos' => {
    repo: 'https://downloads.mariadb.com/ColumnStore/1.1.3/yum/centos/7/x86_64',
    key: 'https://downloads.mariadb.com/ColumnStore/MariaDB-ColumnStore.gpg.key'
  },
  'sles' => {
    repo: 'https://downloads.mariadb.com/ColumnStore/1.1.3/yum/sles/12/x86_64',
    key: 'https://downloads.mariadb.com/ColumnStore/MariaDB-ColumnStore.gpg.key'
  },
  'opensuse' => {
    repo: 'https://downloads.mariadb.com/ColumnStore/1.1.3/yum/sles/12/x86_64',
    key: 'https://downloads.mariadb.com/ColumnStore/MariaDB-ColumnStore.gpg.key'
  },
}
repository_url = if node['columnstore'] && node['columnstore']['repo']
                   node['columnstore']['repo']
                 else
                   default_repos[node[:platform]][:repo]
                 end
repository_key = if node['columnstore'] && node['columnstore']['repo_key']
                   node['columnstore']['repo_key']
                 else
                   default_repos[node[:platform]][:key]
                 end
case node[:platform_family]
when 'debian'
  package 'apt-transport-https' do
    retries 2
    retry_delay 10
  end
  apt_repository 'columnstore' do
    uri repository_url
    key repository_key
    keyserver 'keyserver.ubuntu.com'
    components ['main']
    action :create
  end
when 'rhel', 'sles'
  yum_repository 'columnstore' do
    baseurl repository_url
    gpgkey repository_key
    action :create
  end
end
