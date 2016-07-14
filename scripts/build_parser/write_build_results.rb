#!/usr/bin/env ruby

require 'getoptlong'
require 'json'
require 'mysql2'

# Command line options
INPUT_FILE_OPTION = '--file'
ENV_FILE_OPTION = '--env-file'
HELP_OPTION = '--help'

# Db parameters
DEFAULT_FILE = '/home/vagrant/build_parser_db_password'
HOST = 'localhost'
DB_NAME = 'test_results_db'

# parse_ctest_log.rb keys definition
TEST_NAME = 'test_name'
TEST_SUCCESS = 'test_success'
FAILED = 'Failed'

ERROR = 'Error'

DB_WRITE_ERROR = 'DB_WRITE_ERROR'

class BuildResultsWriter
  attr_accessor :client
  attr_accessor :parsed_content

  def initialize
    @client = nil
    @parsed_content = nil
  end

  def write_results_from_input_file(input_file_path)
    parse_input_file(input_file_path)
    connect_mdb(DEFAULT_FILE, HOST, DB_NAME)

    write_build_results_to_db(@parsed_content)
  end

  def parse_input_file(input_file_path)
    unparsed_content = IO.read(input_file_path)
    @parsed_content = JSON.parse(unparsed_content)
  end

  def connect_mdb(default_file, host, db_name)
    @client = Mysql2::Client.new(:default_file => "#{default_file}", \
      :host => "#{host}", :database => "#{db_name}")
    puts "Connection to db (:default_file => #{default_file}, "\
         ":host => #{host}, :database => #{db_name} established successfuly"
  end

  def write_test_run_table(jenkins_id, start_time, target, box, \
    product, mariadb_version, test_code_commit_id, maxscale_commit_id, job_name)

    test_runs_query = "INSERT INTO test_run (jenkins_id, "\
    "start_time, target, box, product, mariadb_version, "\
    "test_code_commit_id, maxscale_commit_id, job_name) "\
    "VALUES ('#{jenkins_id}', '#{start_time}', '#{target}', '#{box}', '#{product}', "\
    "'#{mariadb_version}', '#{test_code_commit_id}', '#{maxscale_commit_id}', '#{job_name}')"

    @client.query(test_runs_query)
    id = @client.last_id
    puts "Performed insert (test_run, id = #{id}): #{test_runs_query}"
    return id
  end

  def write_results_table(id, test, result)
    results_query = "INSERT INTO results (id, test, result) VALUES ('#{id}', "\
      "'#{test}', '#{result}')"
    @client.query(results_query)
    puts "Performed insert (results): #{results_query}"
  end

  def write_build_results_to_db(results)
    jenkins_id = results['job_build_number']
    start_time = results['timestamp']
    target = results['target']
    box = results['box']
    product = results['product']
    mariadb_version = results['version']
    test_code_commit_id = results['maxscale_system_test_commit'] #? what is that ?
    maxscale_commit_id = results['maxscale_commit']
    job_name = results['job_name']
    tests = Array.new
    if results.has_key? 'tests'
      results['tests'].each do |test|
        tests.push({TEST_NAME => test[TEST_NAME], TEST_SUCCESS => test[TEST_SUCCESS]})
      end
    end

    # writing testrun results to db
    id = write_test_run_table(jenkins_id, start_time, target, box, \
    product, mariadb_version, test_code_commit_id, maxscale_commit_id, job_name)
    
    # writing tests results to db
    unless results.has_key? ERROR
      tests.each do |test|
        puts "Preparing to write test=#{test} into results"
        name = test[TEST_NAME]
        result = 0
        if test[TEST_SUCCESS] == FAILED
          result = 1
        end
        write_results_table(id, name, result)
      end
    end
  end
end


def parse_options
  opts = GetoptLong.new(
      [INPUT_FILE_OPTION, '-f', GetoptLong::REQUIRED_ARGUMENT],
      [ENV_FILE_OPTION, '-e', GetoptLong::OPTIONAL_ARGUMENT],
      [HELP_OPTION, '-h', GetoptLong::OPTIONAL_ARGUMENT]
  )

  input_file_path = nil
  env_file = nil

  opts.each do |opt, arg|
    case opt
      when INPUT_FILE_OPTION
        input_file_path = arg
      when ENV_FILE_OPTION
        env_file = arg
      when HELP_OPTION
        puts <<-EOT
./scripts/build_parser/write_build_results.rb -f parse_ctest_log.rb_results_json_path
    [ -e ]                - ENVIRONMENT VARIABLES FILE, WHERE POSSIBLE DB_WRITING_ERROR CAN BE REPORTED 
    [ -h ]           - SHOW HELP
        EOT
        exit 0
    end
  end
  return input_file_path, env_file
end

def main
  input_file_path, env_file = parse_options

  begin 
    writer = BuildResultsWriter.new
    writer.write_results_from_input_file(input_file_path)
  rescue Exception => e
    puts e.message
    puts e.backtrace
    unless env_file.nil?
      open('env_file', 'a') do |f|
        f.puts "#{DB_WRITE_ERROR} #{e.message}"
      end
    end
  end

end

if File.identical?(__FILE__, $0)
  puts 'Starting ./write_build_results.rb'
  main
  puts './write_build_results.rb finished'
end
