#!/usr/bin/env ruby

# Require test_results_db db created by test_bot using test_results_db.sql


# https://github.com/brianmario/mysql2
# sudo gem install mysql2
require 'mysql2'

def printTable(tableName, client)
  puts tableName
  result = client.query("SELECT * FROM #{tableName}")
  result.each do |row|
    puts row
  end
end

# Connection
client = Mysql2::Client.new(:host => "localhost", :username => "test_bot", :password => "pass", :database => "test_results_db")

# Wrinting data
client.query('INSERT INTO test_run (jenkins_id, start_time, target, box, product, mariadb_version, test_code_commit_id, maxscale_commit_id, job_name) VALUES (1, NOW(), "target", "box", "product", "mariadb_version", "test_code_commit_id", "maxscale_commit_id", "job_name" )')
# Check last id by client field
id = client.last_id
client.query("INSERT INTO results (id, test, result) VALUES (#{id}, 'test', 1)")

# Checking last id in SELECT
#client.query("INSERT INTO results (id, test, result) VALUES ((SELECT id FROM test_run ORDER BY id DESC LIMIT 1), 'test', 1)")

# Printing data
printTable('test_run', client)
printTable('results', client)

