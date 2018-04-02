#!/usr/bin/env ruby
# frozen_string_literal: true

def coredump_find(dir)
  `find #{dir} | grep core | sed -e 's|/[^/]*$|/*|g'`
end

if ARGV.length != 3
  puts <<-EOF
  Usage:
    write_coredump_from_old_logs USER PASSWORD LOGS_DIR

    USER: The database username.
    PASSWORD: The database password.
    LOGS_DIR: The directory with logs.
  EOF
  exit 0
end

USER = ARGV.shift
PASSWORD = ARGV.shift
LOGS_DIR = ARGV.shift.chomp('"').reverse.chomp('"').reverse

HOST = 'localhost'
PORT = '3306'
DB_NAME = 'test_results_db'

require 'mysql2'

begin
  client = Mysql2::Client.new(
    :host => HOST,
    :port => PORT,
    :username => USER,
    :password => PASSWORD,
    :database => DB_NAME
  )
rescue Mysql2::Error => e
  puts e.message
  exit 1
end

puts "START\n------\n"
Dir.glob("#{LOGS_DIR}/run_test*").select do |fn|
  next unless File.directory?(fn)

  coredumps = coredump_find(fn).split("\n")
  next if coredumps.empty?
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
puts "\n------\nFINISH"

