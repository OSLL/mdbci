#!/usr/bin/env ruby
# frozen_string_literal: true

if ARGV.length != 2
  puts <<-EOF
Usage:
  db_migrate USER PASSWORD
  
  USER: The database username.
  PASSWORD: The database password.
  EOF
  exit 0
end

USER = ARGV.shift
PASSWORD = ARGV.shift

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

begin
  start_migrate = if client.query('SHOW TABLES').to_a.empty?
                    0
                  elsif client.query("SHOW TABLES LIKE 'db_metadata'").to_a.empty?
                    1
                  else
                    metadata_hash = client.query('SELECT version FROM db_metadata').to_a.first
                    raise(StandardError, 'Unknown current database version') if metadata_hash.nil?
                    metadata_hash['version'] + 1
                  end
rescue StandardError => e
  puts e.message
  exit 1
end

if start_migrate > 0
  puts "Current database schema version: ##{start_migrate - 1}"
else
  puts 'Database schema is empty'
end

migration_count = Dir.glob('migration-*.sql').size
if start_migrate < migration_count
  start_migrate.upto(migration_count - 1) do |version|
    puts "Apply migrate ##{version}"
    system("mysql --port=#{PORT} --host=#{HOST} --user=#{USER} "\
      "--password=#{PASSWORD} --database=#{DB_NAME} < migration-#{version}.sql")
  end
  puts 'Migration finished'
else
  puts 'You have the latest version of the database schema'
end
