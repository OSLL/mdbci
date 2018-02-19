#!/usr/bin/env ruby
require 'json'
require_relative '../lib/config'
require_relative '../lib/report_portal'
require_relative '../lib/maxscale_report_portal'

if ARGV.length != 2
  puts <<-EOF
Usage:
  upload_testrun LOG_FILE CONFIG_FILE

  LOG_FILE: The parse_ctest_log.rb result json-file path.
  CONFIG_FILE: The config file path.
  EOF
  exit 0
end

INPUT_FILE_NAME = ARGV.shift
CONFIG_FILENAME = ARGV.shift

# ReportPortal options
config = Config.new(CONFIG_FILENAME)

PROJECT_NAME = config.project_name
AUTH_TOKEN = config.auth_token
REPORT_PORTAL_URL = config.report_portal_url
REPOSITORY_URL = config.repository_url
LOGS_DIR_URL = config.logs_dir_url

# JSON file keys
ERROR = 'Error'.freeze

# Class for upload one TestRun from json-file to Report Portal
class BuildResultsUploader
  def initialize
    @report_portal = ReportPortal.new(REPORT_PORTAL_URL, PROJECT_NAME,
                                      AUTH_TOKEN)
    @parsed_content = nil
  end

  def upload_results_from_input_file(input_file_path)
    @parsed_content = JSON.parse(File.read(input_file_path))
    @report_portal.create_project
    upload_to_report_portal(@parsed_content)
  end

  def upload_to_report_portal(results)
    test_run = test_run_from_results(results)

    launch = upload_launch(test_run)

    if results.key?('tests') && !results.key?(ERROR)
      max_test_time = upload_tests(results['tests'], test_run, launch)
    end

    @report_portal.finish_launch(launch,
                                 MaxScaleReportPortal.end_time(test_run, max_test_time))
  end

  private

  def upload_launch(test_run)
    @report_portal.start_launch(
      MaxScaleReportPortal.launch_name(test_run),
      'DEFAULT',
      MaxScaleReportPortal.description(REPOSITORY_URL, LOGS_DIR_URL, test_run),
      MaxScaleReportPortal.start_time(test_run),
      MaxScaleReportPortal.launch_tags(test_run)
    )
  end

  def upload_tests(tests, test_run, launch)
    max_test_time = 0.0

    tests.each do |test|
      test_result = test_result_from_test(test)
      @report_portal.add_root_test_item(
        launch,
        test_result['test'],
        MaxScaleReportPortal.description(REPOSITORY_URL, LOGS_DIR_URL,
                                         test_run, test_result),
        [],
        MaxScaleReportPortal.start_time(test_run),
        'TEST',
        MaxScaleReportPortal.test_tags(test_run, test_result),
        MaxScaleReportPortal.test_result_status(test_result),
        MaxScaleReportPortal.end_time(test_run, test['test_time'])
      )
      max_test_time = test['test_time'].to_f if test['test_time'].to_f > max_test_time
    end
    max_test_time
  end

  def test_result_from_test(test)
    {
      'test' => test['test_name'],
      'result' => test['test_success'] == 'Failed' ? 1 : 0,
      'test_time' => test['test_time']
    }
  end

  def test_run_from_results(results)
    {
      'jenkins_id' => results['job_build_number'],
      'start_time' => results['timestamp'],
      'target' => results['target'],
      'box' => results['box'],
      'product' => results['product'],
      'mariadb_version' => results['version'],
      'test_code_commit_id' => results['maxscale_system_test_commit'], # what is that ?
      'maxscale_commit_id' => results['maxscale_commit'],
      'job_name' => results['job_name'],
      'cmake_flags' => results['cmake_flags'],
      'maxscale_source' => results['maxscale_source'],
      'logs_dir' => results['logs_dir']
    }
  end
end

if File.identical?(__FILE__, $PROGRAM_NAME)
  puts "START\n------\n"
  uploader = BuildResultsUploader.new
  uploader.upload_results_from_input_file(INPUT_FILE_NAME)
  puts "\n------\nFINISH"
end
