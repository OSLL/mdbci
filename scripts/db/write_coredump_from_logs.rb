#!/usr/bin/env ruby
# frozen_string_literal: true

def coredump_find(dir)
  `find #{dir} | grep core | sed -e 's|/[^/]*$|/*|g'`
end

def connect_mdb(default_file, db_name)
  client = Mysql2::Client.new(:default_file => "#{default_file}",  \
      :database => "#{db_name}")
  puts "Connection to db (:default_file => #{default_file}, "\
         ":database => #{db_name} established successfuly"
  client
end

def write_coredump_path_to_db(logs_dir, client)
  return unless File.directory?(logs_dir)

  coredumps = coredump_find(logs_dir).split("\n")
  return if coredumps.empty?
  coredumps.each do |line|
    regex = /.*LOGS\/run_test-(\d+)\/LOGS\/([^\/.+]+)\/*/
    jenkins_id = line.match(regex).captures[0]
    test_name = line.match(regex).captures[1]

    coredump_path_regex = /.*\/run_test-\d+(.+)/
    coredump_path = line.match(coredump_path_regex).captures[0]

    query = "UPDATE results SET core_dump_path = '#{coredump_path}'"\
    "WHERE id IN (SELECT id FROM test_run WHERE jenkins_id=#{jenkins_id}) AND test = '#{test_name}'"
    client.query(query)

    puts "Update Test result with jenkins_id=#{jenkins_id}"
  end
end

if ARGV.length != 1
  puts <<-EOF
  Usage:
    write_coredump_from_logs LOGS_DIR

    LOGS_DIR: The directory with test run logs.

    Example: 'write_coredump_from_logs $HOME/LOGS/run_test-2563'
  EOF
  exit 0
end

LOGS_DIR = ARGV.shift.chomp('"').reverse.chomp('"').reverse

# Db parameters
DEFAULT_FILE = '/home/vagrant/build_parser_db_password'
DB_NAME = 'test_results_db'

puts 'Starting ./write_coredump_from_logs.rb'
begin
  require 'mysql2'
  client = connect_mdb(DEFAULT_FILE, DB_NAME)
  write_coredump_path_to_db(LOGS_DIR, client)
rescue Exception => e
  puts e.message
  puts e.backtrace
  exit 1
end
puts './write_coredump_from_logs.rb finished'




