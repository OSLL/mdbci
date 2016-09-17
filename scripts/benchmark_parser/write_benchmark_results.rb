#!/usr/bin/env ruby

require 'getoptlong'
require 'json'
require 'mysql2'

# Db parameters
DEFAULT_FILE = '/home/vagrant/build_parser_db_password'
DB_NAME = 'test_results_db'

INPUT_FILE_OPTION = '--input-file'
ENV_FILE_OPTION = '--env-file'
SILENT_OPTION = '--silent'
HELP_OPTION = '--help'

DB_WRITE_STATUS = 'DB_WRITE_STATUS'
DB_WRITE_STATUS_SUCCESS = 'Data stored successfuly'

#JSON keys
BUILD_PARAMS = 'build_params'
BENCHMARK_RESULTS = 'benchmark_results'
JENKINS_ID = "jenkins_id"
START_TIME = "start_time"
BOX = "box"
PRODUCT = "product"
MARIADB_VERSION = "mariadb_version"
TEST_CODE_COMMIT_ID = "test_code_commit_id"
PRODUCT_UNDER_TEST = "product_under_test"
JOB_NAME = "job_name"
MACHINE_COUNT = "machine_count"
SYSBENCH_PARAMS = "sysbench_params"
MDBCI_TEMPLATE = "mdbci_template"
TEST_TOOL = "test_tool"
TARGET = "target"
MAXSCALE_COMMIT_ID = "maxscale_commit_id"
MAXSCALE_CNF = "maxscale_cnf"

OLTP_TEST_STATISTICS_QUERIES_PERFORMED_READ = "OLTP_test_statistics_queries_performed_read"
OLTP_TEST_STATISTICS_QUERIES_PERFORMED_WRITE = "OLTP_test_statistics_queries_performed_write"
OLTP_TEST_STATISTICS_QUERIES_PERFORMED_OTHER = "OLTP_test_statistics_queries_performed_other"
OLTP_TEST_STATISTICS_QUERIES_PERFORMED_TOTAL = "OLTP_test_statistics_queries_performed_total"
OLTP_TEST_STATISTICS_TRANSACTIONS = "OLTP_test_statistics_transactions"
OLTP_TEST_STATISTICS_READ_WRITE_REQUESTS = "OLTP_test_statistics_read_write_requests"
OLTP_TEST_STATISTICS_OTHER_OPERATIONS = "OLTP_test_statistics_other_operations"
OLTP_TEST_STATISTICS_IGNORED_ERRORS = "OLTP_test_statistics_ignored_errors"
OLTP_TEST_STATISTICS_RECONNECTS = "OLTP_test_statistics_reconnects"
GENERAL_STATISTICS_TOTAL_TIME = "General_statistics_total_time"
GENERAL_STATISTICS_TOTAL_NUMBER_OF_EVENTS = "General_statistics_total_number_of_events"
GENERAL_STATISTICS_TOTAL_TIME_TAKEN_BY_EVENT_EXECUTION = "General_statistics_total_time_taken_by_event_execution"
GENERAL_STATISTICS_RESPONSE_TIME_MIN = "General_statistics_response_time_min"
GENERAL_STATISTICS_RESPONSE_TIME_AVG = "General_statistics_response_time_avg"
GENERAL_STATISTICS_RESPONSE_TIME_MAX = "General_statistics_response_time_max"
GENERAL_STATISTICS_RESPONSE_TIME_APPROX___95_PERCENTILE = "General_statistics_response_time_approx__95_percentile"
THREADS_FAIRNESS_EVENTS_AVG = "Threads_fairness_events_avg"
THREADS_FAIRNESS_EVENTS_STDDEV = "Threads_fairness_events_stddev"
THREADS_FAIRNESS_EXECUTION_TIME_AVG = "Threads_fairness_execution_time_avg"
THREADS_FAIRNESS_EXECUTION_TIME_STDDEV = "Threads_fairness_execution_time_stddev"


#Products for testing
PRODUCT_MAXSCALE = 'maxscale'

#Benchmarks
BENCHMARK_SYSBENCH = 'sysbench'

def parse_cmd_args
  opts = GetoptLong.new(
      [INPUT_FILE_OPTION, '-i', GetoptLong::REQUIRED_ARGUMENT],
      [ENV_FILE_OPTION, '-e', GetoptLong::REQUIRED_ARGUMENT],
      [SILENT_OPTION, '-s', GetoptLong::OPTIONAL_ARGUMENT],
      [HELP_OPTION, '-h', GetoptLong::OPTIONAL_ARGUMENT]
  )

  options = {}
  opts.each do |opt, arg|
    case opt
      when INPUT_FILE_OPTION
        options[:input_file] = arg
      when ENV_FILE_OPTION
        options[:env_file] = arg
      when SILENT_OPTION
        options[:silent] = true
      when HELP_OPTION
        puts <<-EOT
  Benchmark parser usage:
      write_benchmark_results -i JSON_FILE -e env_file [ -s ]
          [ -i ]                - input json file
          [ -e ]                - env file to create or append
          [ -h ]                - SHOW HELP
        EOT
        exit 0
    end
  end
  if !options.key?(:input_file) or !options.key?(:env_file)
    puts "Not enough arguments. Try -h for help."
    exit 1
  end

  unless File.file?(options[:input_file])
    puts "#{options[:input_file]} does not exist!"
    exit 1
  end

  return options
end

def parse_json_file(input_file)
  puts "parse_json_file #{input_file}"
  file = File.read(input_file)
  hash = JSON.parse(file)
  return hash
end

def write_to_performance_test_run(client, build_params)
  puts "write_to_performance_test_run"

 
  mdbci_template_content = File.read(build_params[MDBCI_TEMPLATE])
  # Submit entry
  performance_test_run_query = "INSERT INTO performance_test_run (jenkins_id, "\
  "start_time, box, product, mariadb_version, "\
  "test_code_commit_id, job_name, machine_count, sysbench_params, "\
  "test_tool, product_under_test, mdbci_template) "\
  "VALUES ('#{build_params[JENKINS_ID]}', '#{build_params[START_TIME]}', "\
  "'#{build_params[BOX]}', '#{build_params[PRODUCT]}', "\
  "'#{build_params[MARIADB_VERSION]}', '#{build_params[TEST_CODE_COMMIT_ID]}', "\
  "'#{build_params[JOB_NAME]}', #{build_params[MACHINE_COUNT]}, "\
  "'#{build_params[SYSBENCH_PARAMS]}', '#{build_params[TEST_TOOL]}', "\
  "'#{build_params[PRODUCT_UNDER_TEST]}', '#{mdbci_template_content}')"

  puts performance_test_run_query  
  client.query(performance_test_run_query)
  test_run_id = client.last_id

  return test_run_id
end

def write_to_product_parameters(client, build_params, test_run_id)
  puts "write_to_product_parameters"

  if build_params[PRODUCT_UNDER_TEST] == PRODUCT_MAXSCALE
    write_to_maxscale_parameters(client, build_params, test_run_id)
  end
  # TODO add actions for other products

end

def write_to_maxscale_parameters(client, build_params, test_run_id)
  puts "write_to_maxscale_parameters"
  maxscale_cnf_content = File.read(build_params[MAXSCALE_CNF])
  maxscale_parameters_query = "INSERT INTO maxscale_parameters "\
  "(id, target, maxscale_commit_id, maxscale_cnf) VALUES ("\
  "#{test_run_id}, '#{build_params[TARGET]}', '#{build_params[MAXSCALE_COMMIT_ID]}', "\
  "'#{maxscale_cnf_content}')"

  puts maxscale_parameters_query
  client.query(maxscale_parameters_query)
end

def write_to_benchmark_results(client, test_tool, benchmark_results, test_run_id)
  puts "write_to_benchmark_results #{test_tool}"
  if test_tool == BENCHMARK_SYSBENCH
    write_to_sysbench_results(client, benchmark_results, test_run_id)
  end 
end

def write_to_sysbench_results(client, benchmark_results, test_run_id)
  puts "write_to_sysbench_results"
  sysbench_results_query = "INSERT INTO sysbench_results (id, "\
  "OLTP_test_statistics_queries_performed_read, "\
  "OLTP_test_statistics_queries_performed_write, "\
  "OLTP_test_statistics_queries_performed_other, "\
  "OLTP_test_statistics_queries_performed_total, "\
  "OLTP_test_statistics_transactions, "\
  "OLTP_test_statistics_read_write_requests, "\
  "OLTP_test_statistics_other_operations, "\
  "OLTP_test_statistics_ignored_errors, "\
  "OLTP_test_statistics_reconnects, "\
  "General_statistics_total_time, "\
  "General_statistics_total_number_of_events, "\
  "General_statistics_total_time_taken_by_event_execution, "\
  "General_statistics_response_time_min, "\
  "General_statistics_response_time_avg, "\
  "General_statistics_response_time_max, "\
  "General_statistics_response_time_approx___95_percentile, "\
  "Threads_fairness_events_avg, "\
  "Threads_fairness_events_stddev, "\
  "Threads_fairness_execution_time_avg, "\
  "Threads_fairness_execution_time_stddev) VALUES ("\
  "#{test_run_id}, "\
  "#{benchmark_results[OLTP_TEST_STATISTICS_QUERIES_PERFORMED_READ]}, "\
  "#{benchmark_results[OLTP_TEST_STATISTICS_QUERIES_PERFORMED_WRITE]}, "\
  "#{benchmark_results[OLTP_TEST_STATISTICS_QUERIES_PERFORMED_OTHER]}, "\
  "#{benchmark_results[OLTP_TEST_STATISTICS_QUERIES_PERFORMED_TOTAL]}, "\
  "#{benchmark_results[OLTP_TEST_STATISTICS_TRANSACTIONS]}, "\
  "#{benchmark_results[OLTP_TEST_STATISTICS_READ_WRITE_REQUESTS]}, "\
  "#{benchmark_results[OLTP_TEST_STATISTICS_OTHER_OPERATIONS]}, "\
  "#{benchmark_results[OLTP_TEST_STATISTICS_IGNORED_ERRORS]}, "\
  "#{benchmark_results[OLTP_TEST_STATISTICS_RECONNECTS]}, "\
  "#{benchmark_results[GENERAL_STATISTICS_TOTAL_TIME]}, "\
  "#{benchmark_results[GENERAL_STATISTICS_TOTAL_NUMBER_OF_EVENTS]}, "\
  "#{benchmark_results[GENERAL_STATISTICS_TOTAL_TIME_TAKEN_BY_EVENT_EXECUTION]}, "\
  "#{benchmark_results[GENERAL_STATISTICS_RESPONSE_TIME_MIN]}, "\
  "#{benchmark_results[GENERAL_STATISTICS_RESPONSE_TIME_AVG]}, "\
  "#{benchmark_results[GENERAL_STATISTICS_RESPONSE_TIME_MAX]}, "\
  "#{benchmark_results[GENERAL_STATISTICS_RESPONSE_TIME_APPROX___95_PERCENTILE]}, "\
  "#{benchmark_results[THREADS_FAIRNESS_EVENTS_AVG]}, "\
  "#{benchmark_results[THREADS_FAIRNESS_EVENTS_STDDEV]}, "\
  "#{benchmark_results[THREADS_FAIRNESS_EXECUTION_TIME_AVG]}, "\
  "#{benchmark_results[THREADS_FAIRNESS_EXECUTION_TIME_STDDEV]} )"

  puts sysbench_results_query
  client.query(sysbench_results_query)
end

def write_results_to_db(hash)
  puts "write_results_to_db #{hash}"
  build_params = hash[BUILD_PARAMS]
  benchmark_results = hash[BENCHMARK_RESULTS]  

  db_write_status = DB_WRITE_STATUS_SUCCESS 
  begin 
    client = Mysql2::Client.new(:default_file => "#{DEFAULT_FILE}",  \
      :database => "#{DB_NAME}")
    test_run_id = write_to_performance_test_run(client, build_params)
    write_to_product_parameters(client, build_params, test_run_id)
    write_to_benchmark_results(client, build_params[TEST_TOOL], benchmark_results, test_run_id)
  rescue => e
    db_write_status = "Error during writing to DB, #{e.message}" 
    puts db_write_status
  end
end

def write_db_result_to_env_file(db_write_status, env_file)
  puts "write_db_result_to_env_file #{db_write_status}, #{env_file}"
  db_editing_env_var = "#{DB_WRITE_STATUS}=#{db_write_status}"
  File.open(env_file, 'a') do |f|
    f.puts db_editing_env_var
  end
end

def validate_hash(hash)
  puts 'validate_hash'
  puts hash.keys
  if !hash.key?(BUILD_PARAMS) or !hash.key?(BENCHMARK_RESULTS)
    puts "JSON should contain both sections - #{BUILD_PARAMS} and #{BENCHMARK_RESULTS}"
    exit 1
  end

end

def main
  options = parse_cmd_args
  hash = parse_json_file(options[:input_file])
  validate_hash(hash)
  
  db_write_status = write_results_to_db(hash)
  write_db_result_to_env_file(db_write_status, options[:env_file])

  puts "Writing results to db completed!"
end

if File.identical?(__FILE__, $0)
  main
end
