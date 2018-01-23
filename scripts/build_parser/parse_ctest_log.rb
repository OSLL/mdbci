#!/usr/bin/env ruby

require 'getoptlong'
require 'fileutils'
require 'json'

LOG_FILE_OPTION = '--log-file'
OUTPUT_LOG_FILE_OPTION = '--output-log-file'
OUTPUT_LOG_JSON_FILE_OPTION = '--output-log-json-file'
ONLY_FAILED_OPTION = '--only-failed'
HUMAN_READABLE_OPTION = '--human-readable'
CTEST_SUBLOGS_PATH = '--ctest-sublogs-path'
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
    'BUILD_NUMBER' => 'Job build number',
    'JOB_NAME' => 'Job name',
    'BUILD_TIMESTAMP' => 'Timestamp',
    'name' => 'Test run name',
    'target' => 'Target',
    'box' => 'Box',
    'product' => 'Product',
    'version' => 'Version'
}

RUN_TEST_BUILD_ENV_VARS_TO_MR = {
    'BUILD_NUMBER' => 'job_build_number',
    'JOB_NAME' => 'job_name',
    'BUILD_TIMESTAMP' => 'timestamp',
    'name' => 'test_run_name',
    'target' => 'target',
    'box' => 'box',
    'product' => 'product',
    'version' => 'version'
}

FIRST_LINES_CTEST_TO_SKIP = [
    'Constructing a list of tests',
    'Done constructing a list of tests',
    'Checking test dependency graph...',
    'Checking test dependency graph end'
]

WORKSPACE = 'WORKSPACE'

FAILED = 'Failed'
PASSED = 'Passed'

NOT_FOUND = 'NOT FOUND'

BUILD_LOG_PARSING_RESULT = 'BUILD_LOG_PARSING_RESULT'

ERROR = 'Error'
CTEST_NOT_EXECUTED_ERROR = 'CTest has never executed'
CTEST_SUMMARY_NOTE_FOUND = 'CTest summary has not found'

CTEST_ARGUMENTS_HR = 'CTest arguments'
CTEST_ARGUMENTS_MR = 'ctest_arguments'

MAXSCALE_COMMIT_HR = "MaxScale commit"
MAXSCALE_COMMIT_MR = "maxscale_commit"

MAXSCALE_SOURCE_HR = "MaxScale source"
MAXSCALE_SOURCE_MR = "maxscale_source"

CMAKE_FLAGS_HR = "CMake flags"
CMAKE_FLAGS_MR = "cmake_flags"

MAXSCALE_SYSTEM_TEST_COMMIT_HR = "MaxScale system test commit"
MAXSCALE_SYSTEM_TEST_COMMIT_MR = "maxscale_system_test_commit"

MAXSCALE_FULL = "Maxscale full version"

NEW_LINE_JENKINS_FORMAT = " \\n\\\n"

opts = GetoptLong.new(
    [LOG_FILE_OPTION, '-l', GetoptLong::REQUIRED_ARGUMENT],
    [ONLY_FAILED_OPTION, '-f', GetoptLong::OPTIONAL_ARGUMENT],
    [HUMAN_READABLE_OPTION, '-r', GetoptLong::OPTIONAL_ARGUMENT],
    [OUTPUT_LOG_FILE_OPTION, '-o', GetoptLong::OPTIONAL_ARGUMENT],
    [OUTPUT_LOG_JSON_FILE_OPTION, '-j', GetoptLong::OPTIONAL_ARGUMENT],
    [CTEST_SUBLOGS_PATH, '-s', GetoptLong::OPTIONAL_ARGUMENT],
    [HELP_OPTION, '-h', GetoptLong::OPTIONAL_ARGUMENT]
)

$log = nil
$only_failed = false
$human_readable = false
$output_log_file_path = nil
$output_log_json_file_path = nil
$ctest_sublogs_path = nil

opts.each do |opt, arg|
  case opt
    when LOG_FILE_OPTION
      begin
        $log = File.read arg
        # Fixing encodings by encoding it to different encoding and back to utf8
        # (because encoding to the same encoding make no effect)
        $log = $log.encode('UTF-16be', :invalid=>:replace).encode('UTF-8')
      rescue
        raise puts "ERROR: Can not find log file: #{arg}"
      end
    when ONLY_FAILED_OPTION
      $only_failed = true
    when HUMAN_READABLE_OPTION
      $human_readable = true
    when OUTPUT_LOG_FILE_OPTION
      $output_log_file_path = arg
    when OUTPUT_LOG_JSON_FILE_OPTION
      $output_log_json_file_path = arg
    when CTEST_SUBLOGS_PATH
      $ctest_sublogs_path = arg
    when HELP_OPTION
      puts <<-EOT
CTest parser usage:
    parse_ctest_log -l CTEST_LOG_FILE_PATH
        [ -f ]                - PARSE ONLY FAILED TESTS
        [ -r ]                - HUMAN READABLE OUTPUT
        [ -o file_path ]      - CTEST PARSER OUTPUT LOG FILE HUMAN READABLE FOR JENKINS (environmental variable format)
        [ -j json_file_path ] - CTEST PARSER OUTPUT LOG JSON FILE (there will be saved all test results - passed and failed)
        [ -h ]                - SHOW HELP
      EOT
      exit 0
  end
end

class CTestParser

  attr_accessor :ctest_executed
  attr_accessor :ctest_summary
  attr_accessor :all_ctest_indexes
  attr_accessor :failed_ctest_indexes
  attr_accessor :all_ctest_arguments
  attr_accessor :failed_ctest_arguments
  attr_accessor :all_ctest_info
  attr_accessor :failed_ctest_info
  attr_accessor :maxscale_commit
  attr_accessor :maxscale_entity
  attr_accessor :fail_ctest_counter

  def initialize
    @ctest_executed = false
    @ctest_summary = nil
    @maxscale_commit = nil
    @cmake_flags = nil
    @maxscale_source = nil
    @all_ctest_indexes = nil
    @failed_ctest_indexes = nil
    @all_ctest_arguments = nil
    @failed_ctest_arguments = nil
    @all_ctest_info = nil
    @failed_ctest_info = nil
    @fail_ctest_counter = nil
    @maxscale_entity = Array.new
  end

  def parse_ctest_log()
    ctest_first_line_regex = /Constructing a list of tests/
    ctest_last_line_regex = /tests passed,.+tests failed out of (.+)/
    maxscale_commit_regex = /MaxScale\s+.*\d+\.*\d*\.*\d*\s+-\s+(.+)/
    cmake_flags_regex = /CMake flags:\s+(.+)/
    maxscale_source_regex = /Source:\s+(.+)/
    maxscale_version_start_regex = /.*Maxscale_full_version_start:.*/
    maxscale_version_end_regex = /.*Maxscale_full_version_end.*/
    ctest_start_line = 0;
    maxscale_version_start_found=false
    maxscale_version_end_found=false
    $log.each_line do |line|
      if line =~ maxscale_version_end_regex
        maxscale_version_end_found=true
      end
      if maxscale_version_start_found and !maxscale_version_end_found and !line.gsub(/\n*/, '').empty?
        @maxscale_entity.push line.gsub(/\n*/, '')
      end
      if line =~ maxscale_version_start_regex
        maxscale_version_start_found=true
      end
      if line =~ maxscale_commit_regex and @maxscale_commit == nil
        @maxscale_commit = line.match(maxscale_commit_regex).captures[0]
      end
      if line =~ cmake_flags_regex and @cmake_flags == nil
        @cmake_flags = line.match(cmake_flags_regex).captures[0].strip
      end
      if line =~ maxscale_source_regex and @maxscale_source == nil
        @maxscale_source = line.match(maxscale_source_regex).captures[0].strip
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
      find_tests_info(ctest_log)
      @all_ctest_info = {TESTS_COUNT => tests_quantity}.merge(@all_ctest_info)
      @failed_ctest_info = {TESTS_COUNT => tests_quantity}.merge(@failed_ctest_info)
    else
      @ctest_summary = CTEST_SUMMARY_NOTE_FOUND
      @all_ctest_info = {TESTS_COUNT => NOT_FOUND, FAILED_TESTS_COUNT => NOT_FOUND, TESTS => []}
      @failed_ctest_info = {TESTS_COUNT => NOT_FOUND, FAILED_TESTS_COUNT => NOT_FOUND, TESTS => []}
    end
  end

  def find_tests_info(ctest_log)
    @all_ctest_indexes = Array.new
    @failed_ctest_indexes = Array.new
    @all_ctest_info = Array.new
    @failed_ctest_info = Array.new
    @fail_ctest_counter = 0
    FileUtils.mkdir_p $ctest_sublogs_path unless $ctest_sublogs_path.nil?
    ctest_sublog = Array.new
    ctest_log.each do |line|
      test_end_regex = /(\d+)\/(\d+)\s+Test\s+#(\d+):[\s]+([^\s]+)\s+[\.\*]+([^\d]+)([\d\.]+)/
      ctest_sublog.push(line) unless FIRST_LINES_CTEST_TO_SKIP.include? line
      if line =~ test_end_regex
        test_index_number = line.match(test_end_regex).captures[0]
        test_success = line.match(test_end_regex).captures[4].strip
        test_name = line.match(test_end_regex).captures[3]
        unless $ctest_sublogs_path.nil?
          Dir.mkdir "#{$ctest_sublogs_path}/#{test_name}"
          File.open("#{$ctest_sublogs_path}/#{test_name}/ctest_sublog", 'w') do |f|
            ctest_sublog.each { |c| f.puts c}
          end
        end
        ctest_sublog = Array.new
        test_number = line.match(test_end_regex).captures[2]
        test_time = line.match(test_end_regex).captures[5]
        @all_ctest_indexes.push(Integer(test_number))
        @all_ctest_info.push({
                                 TEST_INDEX_NUMBER => test_index_number,
                                 TEST_NUMBER => test_number,
                                 TEST_NAME => test_name,
                                 TEST_SUCCESS => test_success,
                                 TEST_TIME => test_time
                             })
        if test_success != PASSED
          @fail_ctest_counter += 1
          @failed_ctest_indexes.push(Integer(test_number))
          @failed_ctest_info.push({
                                      TEST_INDEX_NUMBER => test_index_number,
                                      TEST_NUMBER => test_number,
                                      TEST_NAME => test_name,
                                      TEST_SUCCESS => test_success,
                                      TEST_TIME => test_time
                                  })
        end
      end
    end
    @all_ctest_info = {FAILED_TESTS_COUNT => @fail_ctest_counter, TESTS => @all_ctest_info}
    @failed_ctest_info = {FAILED_TESTS_COUNT => @fail_ctest_counter, TESTS => @failed_ctest_info}
  end

  def generate_ctest_arguments
    return NOT_FOUND unless @ctest_executed
    ctest_arguments = Array.new()
    test_indexes_array = $only_failed ? @failed_ctest_indexes : @all_ctest_indexes
    sorted_test_indexes_array = test_indexes_array.sort
    return NOT_FOUND if sorted_test_indexes_array.size == 0
    sorted_test_indexes_array.each do |test_index|
      if test_index == sorted_test_indexes_array[0]
        ctest_arguments.push(test_index, test_index)
        ctest_arguments.push('1') if sorted_test_indexes_array.size > 1
      else
        ctest_arguments.push(test_index)
      end
    end
    return ctest_arguments.join ','
  end

  def get_test_code_commit
    return NOT_FOUND if ENV[WORKSPACE].nil?
    current_directory = Dir.pwd
    Dir.chdir ENV[WORKSPACE]
    git_log = `git log -1`
    Dir.chdir current_directory
    return NOT_FOUND if git_log.nil?
    commit_regex = /commit\s+(.+)/
    if git_log.lines.first =~ commit_regex
      return git_log.lines.first.match(commit_regex).captures[0]
    end
    return NOT_FOUND
  end

  def generate_run_test_build_parameters_hr
    build_params = Array.new
    RUN_TEST_BUILD_ENV_VARS_TO_HR.each do |key, value|
      env_value = ENV[key] ? ENV[key] : NOT_FOUND
      build_params.push "#{value}: #{env_value}"
    end
    return build_params
  end

  def generate_run_test_build_parameters_mr
    build_params = Hash.new
    RUN_TEST_BUILD_ENV_VARS_TO_MR.each do |key, value|
      env_value = ENV[key] ? ENV[key] : NOT_FOUND
      build_params[value] = env_value
    end
    return build_params
  end

  def generate_hr_result(parsed_ctest_data)
    hr_tests = Array.new
    hr_tests.push @ctest_summary
    parsed_ctest_data[TESTS].each do |test|
      hr_tests.push("#{test[TEST_NUMBER]} - #{test[TEST_NAME]} (#{test[TEST_SUCCESS]})")
    end
    hr_tests.push ''
    hr_tests.push "#{CTEST_ARGUMENTS_HR}: #{generate_ctest_arguments}"
    hr_tests.push ''
    maxscale_commit = @maxscale_commit ? @maxscale_commit : NOT_FOUND
    maxscale_source = @maxscale_source ? @maxscale_source : NOT_FOUND
    cmake_flags = @cmake_flags ? @cmake_flags : NOT_FOUND
    hr_tests.push "#{MAXSCALE_COMMIT_HR}: #{maxscale_commit}"
    hr_tests.push "#{MAXSCALE_SOURCE_HR}: #{maxscale_source}"
    hr_tests.push "#{CMAKE_FLAGS_HR}: #{cmake_flags}"
    hr_tests.push "#{MAXSCALE_SYSTEM_TEST_COMMIT_HR}: #{get_test_code_commit}"
    hr_tests = hr_tests + generate_run_test_build_parameters_hr
    hr_tests.push("#{ERROR}: #{CTEST_NOT_EXECUTED_ERROR}") unless @ctest_executed
    @maxscale_entity.each do |me|
      hr_tests.push "#{MAXSCALE_FULL}: #{me}"
    end
    return hr_tests
  end

  def generate_mr_result(parsed_ctest_data)
    parsed_ctest_data = generate_run_test_build_parameters_mr.merge(parsed_ctest_data)
    parsed_ctest_data = {MAXSCALE_SYSTEM_TEST_COMMIT_MR => get_test_code_commit}.merge(parsed_ctest_data)
    maxscale_commit = @maxscale_commit ? @maxscale_commit : NOT_FOUND
    maxscale_source = @maxscale_source ? @maxscale_source : NOT_FOUND
    cmake_flags = @cmake_flags ? @cmake_flags : NOT_FOUND
    parsed_ctest_data = {MAXSCALE_COMMIT_MR => maxscale_commit,
                         CMAKE_FLAGS_MR => cmake_flags,
                         MAXSCALE_SOURCE_MR => maxscale_source}.merge(parsed_ctest_data)
    parsed_ctest_data = {CTEST_ARGUMENTS_MR => generate_ctest_arguments}.merge(parsed_ctest_data)
    parsed_ctest_data = {ERROR => CTEST_NOT_EXECUTED_ERROR}.merge(parsed_ctest_data) unless @ctest_executed
    return JSON.pretty_generate parsed_ctest_data
  end

  def show_mr_result(parsed_ctest_data)
    puts generate_mr_result(parsed_ctest_data)
  end

  def show_hr_result(parsed_ctest_data)
    puts generate_hr_result(parsed_ctest_data)
  end

  def save_result_to_file()
    open($output_log_file_path, 'w') do |f|
      ctest_info = $only_failed ? @failed_ctest_info : @all_ctest_info
      f.puts [BUILD_LOG_PARSING_RESULT, generate_hr_result(ctest_info)].join(NEW_LINE_JENKINS_FORMAT)
    end
  end

  def save_all_result_to_json_file()
    open($output_log_json_file_path, 'w') do |f|
      f.puts generate_mr_result(@all_ctest_info)
    end
  end


  def show_ctest_parsed_info()
    if !$human_readable
      show_mr_result($only_failed ? @failed_ctest_info : @all_ctest_info)
    else
      show_hr_result($only_failed ? @failed_ctest_info : @all_ctest_info)
    end
  end

  def parse
    parse_ctest_log
    show_ctest_parsed_info
    save_result_to_file if $output_log_file_path
    save_all_result_to_json_file if $output_log_json_file_path
  end

end

def main
  parser = CTestParser.new
  parser.parse
end

if File.identical?(__FILE__, $0)
  main
end
