require 'chef/mixin/shell_out'
require 'shellwords'
include Chef::Mixin::ShellOut

def start_slave_1
  query = ' CHANGE MASTER TO'
  query << " MASTER_HOST='127.0.0.1',"
  query << " MASTER_USER='repl',"
  query << " MASTER_PASSWORD='REPLICAAATE',"
  query << ' MASTER_PORT=3307,'
  query << " MASTER_LOG_POS=#{::File.open('/root/position').read.chomp};"
  query << ' START SLAVE;'
  shell_out("echo \"#{query}\" | /usr/bin/mysql -u root -P3308")
end
# host = -h 127.0.0.1 
# passw = -p#{Shellwords.escape('')}
# password field, add after -P port - -p#{Shellwords.escape('')}
def start_slave_2
  query = ' CHANGE MASTER TO'
  query << " MASTER_HOST='127.0.0.1',"
  query << " MASTER_USER='repl',"
  query << " MASTER_PASSWORD='REPLICAAATE',"
  query << ' MASTER_PORT=3307,'
  query << " MASTER_LOG_POS=#{::File.open('/root/position').read.chomp};"
  query << ' START SLAVE;'
  shell_out("echo \"#{query}\" | /usr/bin/mysql -u root -P3309")
end
