require 'serverspec'

set :backend, :exec

puts "os: #{os}"

def mysql_bin
  return '/opt/mysql51/bin/mysql' if os[:family] =~ /solaris/
  return '/opt/local/bin/mysql' if os[:family] =~ /smartos/
  '/usr/bin/mysql'
end

def mysqld_bin
  return '/opt/mysql51/bin/mysqld' if os[:family] =~ /solaris/
  return '/opt/local/bin/mysqld' if os[:family] =~ /smartos/
  '/usr/sbin/mysqld'
end

def instance_1_cmd
  <<-EOF
  #{mysql_bin} \
  -S /var/run/mysql-instance-1/mysqld.sock \
  -u root \
  -pilikerandompasswords \
  -e "SELECT Host,User FROM mysql.user WHERE User='root' AND Host='localhost';" \
  --skip-column-names
  EOF
end

def instance_2_cmd
  <<-EOF
  #{mysql_bin} \
  -S /var/run/mysql-instance-2/mysqld.sock \
  -u root \
  -pstring\\ with\\ spaces \
  -e "SELECT Host,User FROM mysql.user WHERE User='root' AND Host='localhost';" \
  --skip-column-names
  EOF
end

def mysqld_cmd
  "#{mysqld_bin} --version"
end

describe command(instance_1_cmd) do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/| localhost | root |/) }
end

describe command(instance_2_cmd) do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/| localhost | root |/) }
end

describe command(mysqld_cmd) do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/Ver 5.7/) }
end
