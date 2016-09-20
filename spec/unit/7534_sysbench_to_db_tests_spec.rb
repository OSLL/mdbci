require 'rspec'
require 'fileutils'
require_relative '../../core/helper'
require_relative '../../scripts/benchmark_parser/write_benchmark_results'

# !!!Redefines db in write_benchmark_results!!!
DB_NAME = 'mdbci_dev_db_benchmark_parser_testing'
DEFAULT_FILE = './scripts/db/defaults_file_dev'

PARSER_ENV_FILE = './spec/7534_sysbench_to_db_tests_parser_env_file.env'
PARSER_OUT_FILE = './spec/7534_sysbench_to_db_tests_parser_out_file.json'
PARSER_IN_FILE = './spec/configs/scripts/sysbench/sysbench_test_log'

BENCHMARK_ENV_FILE = './spec/7534_sysbench_to_db_tests_benchmark_env_file.env'

maxscale_parameters = {
    'id' => 1,
    'target' => 'notfound',
    'maxscale_commit_id' => 'e70e64493c995e40ccbfd9277e95f2b74033bc5b',
    'maxscale_cnf' => 'test'
}

performance_test_run = {
    'id' => 1,
    'jenkins_id' => 0,
    'start_time' => nil,
    'box' => 'notfound',
    'product' => 'notfound',
    'mariadb_version' => 'notfound',
    'test_code_commit_id' => 'notfound',
    'job_name' => 'notfound',
    'machine_count' => 0,
    'sysbench_params' => 'notfound',
    'mdbci_template' => 'confs/libvirt_lite.json',
    'test_tool' => 'sysbench',
    'product_under_test' => 'maxscale'
}

benchmark_results = {
    "id"=>1,
    "OLTP_test_statistics_queries_performed_read"=>380226.0,
    "OLTP_test_statistics_queries_performed_write"=>108580.0,
    "OLTP_test_statistics_queries_performed_other"=>54296.0,
    "OLTP_test_statistics_queries_performed_total"=>543102.0,
    "OLTP_test_statistics_transactions"=>27137.0,
    "OLTP_test_statistics_read_write_requests"=>488806.0,
    "OLTP_test_statistics_other_operations"=>54296.0,
    "OLTP_test_statistics_ignored_errors"=>22.0,
    "OLTP_test_statistics_reconnects"=>0.0,
    "General_statistics_total_time"=>300.835,
    "General_statistics_total_number_of_events"=>27137.0,
    "General_statistics_total_time_taken_by_event_execution"=>9607.26,
    "General_statistics_response_time_min"=>94.91,
    "General_statistics_response_time_avg"=>354.03,
    "General_statistics_response_time_max"=>2385.22,
    "General_statistics_response_time_approx__95_percentile"=>791.99,
    "Threads_fairness_events_avg"=>848.031,
    "Threads_fairness_events_stddev"=>14.92,
    "Threads_fairness_execution_time_avg"=>300.227,
    "Threads_fairness_execution_time_stddev"=>0.19
}


def prepare_env_vars
  env_vars = [
      'BUILD_NUMBER',
      'BUILD_TIMESTAMP',
      'box',
      'product',
      'version',
      'machine_count',
      'sysbench_params',
      'machines_count',
      'target',
      'JOB_NAME'
  ]
  env_vars.each { |ev| ENV[ev] = ev }
  ENV['name'] = 'spec/configs/generated_config/7534_sysbench_to_db_tests'
  ENV['WORKSPACE'] = Dir.pwd
  File.open('maxscale.cnf', 'w') { |file| file.write('test') }
end

options = Hash.new
hash = nil
db_write_status = nil
client = nil

describe nil do

  before :all do
    execute_bash("./scripts/benchmark_parser/parse_log.rb -e #{PARSER_ENV_FILE} -o #{PARSER_OUT_FILE} -i #{PARSER_IN_FILE}")
    execute_bash('./scripts/db/benchmark_parser/recreate_test_db.sh')
    options[:input_file] = PARSER_OUT_FILE
    options[:env_file] = BENCHMARK_ENV_FILE
    prepare_env_vars
    hash = parse_json_file(options[:input_file])
    hash[BUILD_PARAMS][MDBCI_TEMPLATE]='./spec/configs/generated_config/7534_sysbench_to_db_tests/template'
    puts File.read 'maxscale.cnf'
    hash[BUILD_PARAMS][MAXSCALE_CNF]='maxscale.cnf'
    hash[BUILD_PARAMS][MACHINE_COUNT]='0'
    hash[BUILD_PARAMS][JENKINS_ID]='0'
    hash[BUILD_PARAMS][JOB_NAME]='notfound'
    validate_hash(hash)
    puts JSON.pretty_generate hash
    client = Mysql2::Client.new(:default_file => "#{DEFAULT_FILE}", :database => "#{DB_NAME}")
  end

  after :all do
    FileUtils.rm_rf PARSER_ENV_FILE
    FileUtils.rm_rf PARSER_OUT_FILE
    FileUtils.rm_rf BENCHMARK_ENV_FILE
    FileUtils.rm_rf 'maxscale.cnf'
    execute_bash('./scripts/db/benchmark_parser/drop_test_db.sh')
  end

  it 'check if ./scripts/benchmark_parser/write_benchmark_results.rb fills database correctly' do
    db_write_status = write_results_to_db(hash)
    client.query('select * from maxscale_parameters').each { |row| row.should eql maxscale_parameters}
    client.query('select * from performance_test_run').each { |row| row.should eql performance_test_run }
    client.query('select * from sysbench_results').each { |row| row.should eql  benchmark_results }
  end

  it 'check if ./scripts/benchmark_parser/write_benchmark_results.rb fills env file correctly' do
    write_db_result_to_env_file(db_write_status, options[:env_file])
    File.read(BENCHMARK_ENV_FILE).should eql "DB_WRITE_STATUS=Data stored successfuly\n"
  end

end

