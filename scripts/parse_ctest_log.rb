#!/usr/bin/env ruby

require 'getoptlong'
require 'json'

LOG_FILE_OPTION = '--log-file'
ONLY_FAILED_OPTION = '--only-failed'

TEST_NUMBER = 'test_number'
TEST_NAME = 'test_name'
TEST_SUCCESS = 'test_success'
TESTS = 'tests'
TESTS_COUNT = 'tests_count'
FAILED_TESTS_COUNT = 'failed_tests_count'

FAILED = 'Failed'
PASSED = 'Passed'

opts = GetoptLong.new(
    [LOG_FILE_OPTION, '-l', GetoptLong::REQUIRED_ARGUMENT],
    [ONLY_FAILED_OPTION, '-f', GetoptLong::OPTIONAL_ARGUMENT],
)

$log_file_path = nil

opts.each do |opt, arg|
  case opt
    when LOG_FILE_OPTION
      $log_file_path = arg
  end
end

def parseCtestLog()
  log = nil
  begin
    log = File.read $log_file_path
  rescue
    at_exit {puts "ERROR: Can not find log file: #{$log_file_path}"}
    exit 1
  end
  ctest_first_line_regex = /Constructing a list of tests/
  ctest_last_line_regex = /tests passed, .+ tests failed out of (.+)/
  ctest_start_line = 0;
  first_line_found = false;
  log.each_line do |line|
    if line =~ ctest_first_line_regex
      first_line_found = true;
      break
    end
    ctest_start_line += 1
  end
  unless first_line_found
    at_exit {puts "ERROR: Can not find CTest information (maybe it was not executed)"}
    exit 1
  end
  ctest_log = log.split("\n")[ctest_start_line..-1]
  ctest_end_line = 0;
  ctest_log.each do |line|
    break if line =~ ctest_last_line_regex
    ctest_end_line += 1
  end
  ctest_log = ctest_log[0..ctest_end_line]
  tests_quantity = ctest_log[-1].match(ctest_last_line_regex).captures[0]
  return {TESTS_COUNT=>tests_quantity}.merge findTestsInfo(ctest_log, tests_quantity)
end

def findTestsInfo(ctest_log, tests_quantity)
  tests_info = Array.new
  failed_tests_counter = 0
  test_counter = 1
  real_test_num = nil
  test_start_found = false
  current_test_name = nil
  ctest_log.each do |line|
    if line =~ /^test \d+$/
      test_start_found = true
      real_test_num = line.match(/^test (\d+)$/).captures[0]
    elsif test_start_found && !real_test_num.nil?
      test_start_found = false
      current_test_name = line.match(/Start #{real_test_num}: (.+)/).captures[0]
    elsif !current_test_name.nil? && !real_test_num.nil?
      test_end_regex = /#{test_counter}\/#{tests_quantity} Test ##{real_test_num}: #{current_test_name} .+(Failed|Passed)/
      if line =~ test_end_regex
        test_success = line.match(test_end_regex).captures[0]
        if test_success == (FAILED)
          failed_tests_counter += 1
        end
        tests_info.push(real_test_num=>{TEST_NAME=>current_test_name, TEST_SUCCESS=>test_success})
        current_test_name = nil
        real_test_num = nil
        test_counter += 1
      end
    end
    break if (test_counter - 1) == tests_quantity
  end
  return {FAILED_TESTS_COUNT=>failed_tests_counter, TESTS=>tests_info}
end


puts JSON.pretty_generate(parseCtestLog())