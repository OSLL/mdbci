#!/usr/bin/env ruby

require 'getoptlong'
require 'json'

LOG_FILE_OPTION = '--log-file'
OUTPUT_LOG_FILE_OPTION = '--output-log-file'
ONLY_FAILED_OPTION = '--only-failed'
HUMAN_READABLE_OPTION = '--human-readable'
HELP_OPTION = '--help'

TEST_INDEX_NUMBER = 'test_index_number'
TEST_NUMBER = 'test_number'
TEST_NAME = 'test_name'
TEST_SUCCESS = 'test_success'
TEST_TIME = 'test_time'
TESTS = 'tests'
TESTS_COUNT = 'tests_count'
FAILED_TESTS_COUNT = 'failed_tests_count'

RUN_TEST_BUILD_ENV_VARS_TO_HR = {
  'BUILD_NUMBER'=>'Buid number',
  'JOB_NAME'=>'Job name',
  'BUILD_TIMESTAMP'=>'Timestamp',
  'name'=>'Test run name',
  'target'=>'Target',
  'box'=>'Box',
  'product'=>'Product',
  'version'=>'Version'
}

RUN_TEST_BUILD_ENV_VARS_TO_MR = {
  'BUILD_NUMBER'=>'buid_number',
  'JOB_NAME'=>'job_name',
  'BUILD_TIMESTAMP'=>'timestamp',
  'name'=>'test_run_name',
  'target'=>'target',
  'box'=>'box',
  'product'=>'product',
  'version'=>'version'
}

FAILED = 'Failed'
PASSED = 'Passed'

NOT_FOUND = 'NOT FOUND'

BUILD_LOG_PARSING_RESULT = 'BUILD_LOG_PARSING_RESULT'

ERROR = 'ERROR'
CTEST_NOT_EXECUTED_ERROR = 'CTest never been executed'

CTEST_ARGUMENTS_HR = 'CTest arguments'
CTEST_ARGUMENTS_MR = 'ctest_arguments'

MAXSCALE_COMMIT_HR = "MaxScale commit"
MAXSCALE_COMMIT_MR = "maxscale_commit"

NEW_LINE_JENKINS_FORMAT = " \\\n"

opts = GetoptLong.new(
    [LOG_FILE_OPTION, '-l', GetoptLong::REQUIRED_ARGUMENT],
    [ONLY_FAILED_OPTION, '-f', GetoptLong::OPTIONAL_ARGUMENT],
    [HUMAN_READABLE_OPTION, '-r', GetoptLong::OPTIONAL_ARGUMENT],
    [OUTPUT_LOG_FILE_OPTION, '-o', GetoptLong::OPTIONAL_ARGUMENT],
    [HELP_OPTION, '-h', GetoptLong::OPTIONAL_ARGUMENT]
)

$log = nil
$only_failed = false
$human_readable = false
$output_log_file_path = nil

opts.each do |opt, arg|
  case opt
    when LOG_FILE_OPTION
      begin
        $log = File.read arg
      rescue
        raise puts "ERROR: Can not find log file: #{arg}"
      end
    when ONLY_FAILED_OPTION
      $only_failed = true
    when HUMAN_READABLE_OPTION
      $human_readable = true
    when OUTPUT_LOG_FILE_OPTION
      $output_log_file_path = arg
    when HELP_OPTION
      puts <<-EOT
CTest parser usage:
    parse_ctest_log -l CTEST_LOG_FILE_PATH
        [ -f ]           - PARSE ONLY FAILED TESTS
        [ -r ]           - HUMAN READABLE OUTPUT
        [ -e ]           - HUMAN READABLE FULL OUTPUT
        [ -o file_path ] - CTEST PARSER OUTPUT LOG FILE
        [ -h ]           - SHOW HELP
      EOT
      exit 0
  end
end

class CTestParser

  attr_accessor :ctest_executed
  attr_accessor :ctest_summary
  attr_accessor :ctest_test_indexes
  attr_accessor :ctest_arguments
  attr_accessor :maxscale_commit

  def initialize
    @ctest_executed = false
    @ctest_summary = nil
    @ctest_test_indexes = Array.new
    @ctest_arguments = nil
    @maxscale_commit = nil
  end

  def parseCTestLog()
    ctest_first_line_regex = /Constructing a list of tests/
    ctest_last_line_regex = /tests passed,.+tests failed out of (.+)/
    maxscale_commit_regex = /MaxScale\s+.*\d+\.*\d*\.*\d*\s+-\s+(.+)/
    ctest_start_line = 0;
    $log.each_line do |line|
      if line =~ maxscale_commit_regex and @maxscale_commit == nil
        @maxscale_commit = line.match(maxscale_commit_regex).captures[0]
      end
      if line =~ ctest_first_line_regex
        @ctest_executed = true
        break
      end
      ctest_start_line += 1
    end
    if @ctest_executed
      ctest_log = $log.split("\n")[ctest_start_line..-1]
      ctest_end_line = 0
      ctest_log.each do |line|
        if line =~ ctest_last_line_regex
          @ctest_summary = line
          break
        end
        ctest_end_line += 1
      end
      ctest_log = ctest_log[0..ctest_end_line]
      tests_quantity = ctest_log[-1].match(ctest_last_line_regex).captures[0]
      return {TESTS_COUNT=>tests_quantity}.merge findTestsInfo(ctest_log)
    end
    return nil
  end

  def findTestsInfo(ctest_log)
    tests_info = Array.new
    failed_tests_counter = 0
    ctest_log.each do |line|
      test_end_regex = /(\d+)\/(\d+)\s+Test\s+#(\d+):[\s]+([^\s\.]+)[\s\.\*]+(Passed|Failed)\s+([\d\.]+)/
      if line =~ test_end_regex
        test_index_number = line.match(test_end_regex).captures[0]
        test_number = line.match(test_end_regex).captures[2]
        test_name = line.match(test_end_regex).captures[3]
        test_success = line.match(test_end_regex).captures[4]
        test_time = line.match(test_end_regex).captures[5]
        if test_success == (FAILED)
          failed_tests_counter += 1
        end
        if test_success == FAILED or (!$only_failed and test_success == PASSED)
          @ctest_test_indexes.push Integer test_number
          tests_info.push({
              TEST_INDEX_NUMBER=>test_index_number,
              TEST_NUMBER=>test_number,
              TEST_NAME=>test_name ,
              TEST_SUCCESS=>test_success,
              TEST_TIME=>test_time
          })
        end
      end
    end
    if tests_info.length > 0
      return {FAILED_TESTS_COUNT=>failed_tests_counter, TESTS=>tests_info}
    else
      return {FAILED_TESTS_COUNT=>failed_tests_counter}
    end
  end

  def generateCTestArgument(test_indexes_array)
    ctest_arguments = Array.new()
    sorted_test_indexes_array = test_indexes_array.sort
    if sorted_test_indexes_array.size == 0
      return NOT_FOUND
    end
    sorted_test_indexes_array.each do |test_index|
      if test_index == sorted_test_indexes_array[0]
        ctest_arguments.push(test_index, test_index)
        if sorted_test_indexes_array.size > 1
          ctest_arguments.push(' ')
        end
      else
        ctest_arguments.push(test_index)
      end
    end
    return ctest_arguments.join ','
  end

  def generateRunTestBuildParametersHumanReadable
    build_params = Array.new
    RUN_TEST_BUILD_ENV_VARS_TO_HR.each do |key, value|
      build_params.push "#{value}: #{if ENV[key] then ENV[key] else NOT_FOUND end}"
    end
    return build_params
  end

  def generateRunTestBuildParametersMachineReadable
    build_params = Hash.new
    RUN_TEST_BUILD_ENV_VARS_TO_MR.each do |key, value|
      build_params[value]= if ENV[key] then ENV[key] else NOT_FOUND end
    end
    return build_params
  end

  def generateHumanReadableInfo(parsedCTestInfo)
    hr_tests = Array.new
    if @ctest_executed
      hr_tests.push @ctest_summary
      hr_tests.push "#{CTEST_ARGUMENTS_HR}: #{generateCTestArgument(@ctest_test_indexes)}"
      hr_tests.push "#{MAXSCALE_COMMIT_HR}: #{if @maxscale_commit != nil then @maxscale_commit  else NOT_FOUND end}"
      hr_tests = hr_tests + generateRunTestBuildParametersHumanReadable
      if parsedCTestInfo.has_key? TESTS
        parsedCTestInfo[TESTS].each do |test|
          hr_tests.push("#{test[TEST_NUMBER]} - #{test[TEST_NAME]} (#{test[TEST_SUCCESS]})")
        end
      end
    else
      hr_tests.push("#{ERROR}: #{CTEST_NOT_EXECUTED_ERROR}")
    end
    return hr_tests
  end

  def showMachineReadableParsedInfo(parsed_ctest_data)
    if @ctest_executed
      parsed_ctest_data = generateRunTestBuildParametersMachineReadable.merge(parsed_ctest_data)
      parsed_ctest_data = {MAXSCALE_COMMIT_MR=>if @maxscale_commit != nil then @maxscale_commit  else NOT_FOUND end}.merge(parsed_ctest_data)
      parsed_ctest_data = {CTEST_ARGUMENTS_MR=>generateCTestArgument(@ctest_test_indexes)}.merge(parsed_ctest_data)
      puts JSON.pretty_generate(parsed_ctest_data)
    elsif
      puts "{#{ERROR}: #{CTEST_NOT_EXECUTED_ERROR}}"
    end
  end

  def showHumanReadableParsedInfo(parsed_ctest_data)
    puts generateHumanReadableInfo(parsed_ctest_data)
  end

  def saveParsedDataToEnvironmentalFile(parsed_ctest_data)
    open($output_log_file_path, 'w') do |f|
      f.puts "#{BUILD_LOG_PARSING_RESULT}= \\"
      f.puts generateHumanReadableInfo(parsed_ctest_data).join(NEW_LINE_JENKINS_FORMAT)
    end
  end

  def showParsedInfo (parsed_ctest_data)
    if !$human_readable
      showMachineReadableParsedInfo parsed_ctest_data
    else
      showHumanReadableParsedInfo parsed_ctest_data
    end
  end

  def parse
    parsed_ctest_data = parseCTestLog
    showParsedInfo parsed_ctest_data
    if !$output_log_file_path.nil?
      saveParsedDataToEnvironmentalFile parsed_ctest_data
    end
  end
end

def main
  parser = CTestParser.new
  parser.parse
end

main if File.identical?(__FILE__, $0)
