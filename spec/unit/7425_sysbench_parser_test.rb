require 'rspec'
require 'yaml'
require_relative '../../core/helper'
require_relative '../../scripts/benchmark_parser/parse_log'

LOG_FILE = 'spec/configs/scripts/sysbench/sysbench_test_log'

ENV_FILE = 'spec/sysbench_test_env_file'

SYSBENCH_OUTPUT = <<EOF
OLTP test statistics:
    queries performed:
        read:                            380226
        write:                           108580
        other:                           54296
        total:                           543102
    transactions:                        27137  (90.21 per sec.)
    read/write requests:                 488806 (1624.83 per sec.)
    other operations:                    54296  (180.48 per sec.)
    ignored errors:                      22     (0.07 per sec.)
    reconnects:                          0      (0.00 per sec.)

General statistics:
    total time:                          300.8348s
    total number of events:              27137
    total time taken by event execution: 9607.2601s
    response time:
         min:                                 94.91ms
         avg:                                354.03ms
         max:                               2385.22ms
         approx.  95 percentile:             791.99ms

Threads fairness:
    events (avg/stddev):           848.0312/14.92
    execution time (avg/stddev):   300.2269/0.19
EOF

flatte_hash = {
    "OLTP_test_statistics_queries_performed_read" => 380226,
    "OLTP_test_statistics_queries_performed_write" => 108580,
    "OLTP_test_statistics_queries_performed_other" => 54296,
    "OLTP_test_statistics_queries_performed_total" => 543102,
    "OLTP_test_statistics_transactions" => "27137  (90.21 per sec.)",
    "OLTP_test_statistics_read/write_requests" => "488806 (1624.83 per sec.)",
    "OLTP_test_statistics_other_operations" => "54296  (180.48 per sec.)",
    "OLTP_test_statistics_ignored_errors" => "22     (0.07 per sec.)",
    "OLTP_test_statistics_reconnects" => "0      (0.00 per sec.)",
    "General_statistics_total_time" => "300.8348s",
    "General_statistics_total_number_of_events" => 27137,
    "General_statistics_total_time_taken_by_event_execution" => "9607.2601s",
    "General_statistics_response_time_min" => "94.91ms",
    "General_statistics_response_time_avg" => "354.03ms",
    "General_statistics_response_time_max" => "2385.22ms",
    "General_statistics_response_time_approx__95_percentile" => "791.99ms",
    "Threads_fairness_events_(avg/stddev)" => "848.0312/14.92",
    "Threads_fairness_execution_time_(avg/stddev)" => "300.2269/0.19"
}
clean_hash={
    "OLTP_test_statistics_queries_performed_read" => 380226,
    "OLTP_test_statistics_queries_performed_write" => 108580,
    "OLTP_test_statistics_queries_performed_other" => 54296,
    "OLTP_test_statistics_queries_performed_total" => 543102,
    "OLTP_test_statistics_transactions" => 27137.0,
    "OLTP_test_statistics_read/write_requests" => 488806.0,
    "OLTP_test_statistics_other_operations" => 54296.0,
    "OLTP_test_statistics_ignored_errors" => 22.0,
    "OLTP_test_statistics_reconnects" => 0.0, "General_statistics_total_time" => 300.8348,
    "General_statistics_total_number_of_events" => 27137,
    "General_statistics_total_time_taken_by_event_execution" => 9607.2601,
    "General_statistics_response_time_min" => 94.91,
    "General_statistics_response_time_avg" => 354.03,
    "General_statistics_response_time_max" => 2385.22,
    "General_statistics_response_time_approx__95_percentile" => 791.99,
    "Threads_fairness_events_(avg/stddev)" => 848.0312,
    "Threads_fairness_execution_time_(avg/stddev)" => 300.2269
}
no_slash_keys_hash={
    "OLTP_test_statistics_queries_performed_read" => 380226,
    "OLTP_test_statistics_queries_performed_write" => 108580,
    "OLTP_test_statistics_queries_performed_other" => 54296,
    "OLTP_test_statistics_queries_performed_total" => 543102,
    "OLTP_test_statistics_transactions" => "27137  (90.21 per sec.)",
    "OLTP_test_statistics_read/write_requests" => "488806 (1624.83 per sec.)",
    "OLTP_test_statistics_other_operations" => "54296  (180.48 per sec.)",
    "OLTP_test_statistics_ignored_errors" => "22     (0.07 per sec.)",
    "OLTP_test_statistics_reconnects" => "0      (0.00 per sec.)",
    "General_statistics_total_time" => "300.8348s",
    "General_statistics_total_number_of_events" => 27137,
    "General_statistics_total_time_taken_by_event_execution" => "9607.2601s",
    "General_statistics_response_time_min" => "94.91ms",
    "General_statistics_response_time_avg" => "354.03ms",
    "General_statistics_response_time_max" => "2385.22ms",
    "General_statistics_response_time_approx__95_percentile" => "791.99ms",
    "Threads_fairness_events_avg" => "848.0312",
    "Threads_fairness_events_stddev" => "14.92",
    "Threads_fairness_execution_time_avg" => "300.2269",
    "Threads_fairness_execution_time_stddev" => "0.19"
}
env_file_content = String.new
#SYSBENCH_OUTPUT.each_line { |l| env_file_content+="#{l}".delete("\n"); env_file_content+=" \\\n"}
env_file_content = "SYSBENCH_RESULTS_RAW \\\n#{SYSBENCH_OUTPUT.gsub("\n", " \\\n")}"

describe nil do

  after :all do
    FileUtils.rm ENV_FILE
  end

  it 'parsing non-existing test log for sysbench output' do
    expect { extract_sysbench_results_raw('NOT EXIST') }.to raise_error Errno::ENOENT
  end

  it 'parsing test log for sysbench output' do
    expect(extract_sysbench_results_raw(LOG_FILE)).to eql SYSBENCH_OUTPUT + "\n"
  end

  it 'write sysbench output to env file' do
    results_raw = extract_sysbench_results_raw(LOG_FILE)
    write_sysbench_results_to_env_file(results_raw, ENV_FILE)
    expect(File.read(ENV_FILE)).to eql env_file_content + " \n"
  end

  it 'converts raw result to yaml' do
    results_raw = extract_sysbench_results_raw(LOG_FILE)
    expect(parse_sysbench_results_raw(results_raw)).to eql YAML.load(results_raw)
  end

  it 'flattens keys in parsed sysbench log' do
    results_raw = extract_sysbench_results_raw(LOG_FILE)
    hash = parse_sysbench_results_raw(results_raw)
    expect(flatten_keys(hash)).to eql flatte_hash
  end

  it 'cleans values in parsed sysbench log' do
    results_raw = extract_sysbench_results_raw(LOG_FILE)
    hash = parse_sysbench_results_raw(results_raw)
    flatten_hash = flatten_keys(hash)
    expect(clean_values(flatten_hash)).to eql clean_hash
  end

  it 'cleans values in parsed sysbench log' do
    results_raw = extract_sysbench_results_raw(LOG_FILE)
    hash = parse_sysbench_results_raw(results_raw)
    hash = flatten_keys(hash)
    expect(split_slash_keys(hash)).to eql no_slash_keys_hash
  end

end
