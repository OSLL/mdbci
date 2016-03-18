#!/usr/bin/env ruby

require 'getoptlong'
require 'json'

LOG_FILE_OPTION = '--log-file'
OUTPUT_LOG_FILE_OPTION = '--output-log-file'
ONLY_FAILED_OPTION = '--only-failed'
HUMAN_READABLE_OPTION = '--human-readable'
HELP_OPTION = '--help'

TEST_NUMBER = 'test_number'
TEST_NAME = 'test_name'
TEST_SUCCESS = 'test_success'
TESTS = 'tests'
TESTS_COUNT = 'tests_count'
FAILED_TESTS_COUNT = 'failed_tests_count'

FAILED = 'Failed'
PASSED = 'Passed'

TIME_NOW = Time.now.strftime('[%d.%m.%Y %H:%M:%s]')

opts = GetoptLong.new(
    [LOG_FILE_OPTION, '-l', GetoptLong::REQUIRED_ARGUMENT],
    [ONLY_FAILED_OPTION, '-f', GetoptLong::OPTIONAL_ARGUMENT],
    [HUMAN_READABLE_OPTION, '-r', GetoptLong::OPTIONAL_ARGUMENT],
    [OUTPUT_LOG_FILE_OPTION, '-o', GetoptLong::OPTIONAL_ARGUMENT],
    [HELP_OPTION, '-h', GetoptLong::OPTIONAL_ARGUMENT]
)

$log_file_path = nil
$only_failed = false
$human_readable = false
$output_log_file_path = nil

opts.each do |opt, arg|
  case opt
    when LOG_FILE_OPTION
      $log_file_path = arg
    when ONLY_FAILED_OPTION
      $only_failed = true
    when HUMAN_READABLE_OPTION
      $human_readable = true
    when OUTPUT_LOG_FILE_OPTION
      $output_log_file_path = arg
    when HELP_OPTION
      puts <<-EOT
CTest parser usage:
    parse_ctest_log -l ctest_log_file_path
        [-f true|false] - PARSE ONLY FAILED TESTS
        [-r true|false] - HUMAN READABLE OUTPUT
        [-o file_path] - CTEST PARSER OUTPUT LOG FILE
        [-h help] - SHOW HELP
      EOT
      exit 0
  end
end

def parseCtestLog()
  log = nil
  begin
    log = File.read $log_file_path
  rescue
    raise puts "ERROR: Can not find log file: #{$log_file_path}"
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
  raise puts "ERROR: Can not find CTest information (maybe it was not executed)" unless first_line_found
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
        if test_success == FAILED or (!$only_failed and test_success == PASSED)
          tests_info.push({TEST_NUMBER=>real_test_num, TEST_NAME=>current_test_name, TEST_SUCCESS=>test_success})
        end
        current_test_name = nil
        real_test_num = nil
        test_counter += 1
      end
    end
    break if (test_counter - 1) == tests_quantity
  end
  return {FAILED_TESTS_COUNT=>failed_tests_counter, TESTS=>tests_info}
end

def generateHumanReadableInfo(parsedCTestInfo)
  hr_tests = Array.new
  parsedCTestInfo[TESTS].each do |test|
    hr_tests.push("#{test[TEST_NUMBER]} - #{test[TEST_NAME]} - #{test[TEST_SUCCESS]}")
  end
  return hr_tests
end

def showParsedInfo
  parsed_ctest_data = parseCtestLog
  if !$human_readable
    puts JSON.pretty_generate(parsed_ctest_data)
  elsif
    generateHumanReadableInfo(parsed_ctest_data).each { |line| puts line }
  end
  open($output_log_file_path, 'a') do |f|
    generateHumanReadableInfo(parsed_ctest_data).each do |line|
      f.puts "#{TIME_NOW} #{line}"
    end
  end
end

showParsedInfo
