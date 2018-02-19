#!/usr/bin/env ruby
require_relative '../lib/config'
require_relative '../lib/report_portal'
require_relative '../lib/maxscale_report_portal'

if ARGV.length != 1
  puts <<-EOF
Usage:
  upload_all_testruns CONFIG_FILE

  CONFIG_FILE: The config file path.
  EOF
  exit 0
end

CONFIG_FILENAME = ARGV.shift

config = Config.new(CONFIG_FILENAME)
USER = config.user
PASSWORD = config.password
PROJECT_NAME = config.project_name
TEST_RUN_COUNT = config.test_run_count
DB_NAME = config.db_name
AUTH_TOKEN = config.auth_token
REPORT_PORTAL_URL = config.report_portal_url
REPOSITORY_URL = config.repository_url
LOGS_DIR_URL = config.logs_dir_url

require 'mysql2'

client = Mysql2::Client.new(username: USER, password: PASSWORD,
                            database: DB_NAME)
report_portal = ReportPortal.new(REPORT_PORTAL_URL, PROJECT_NAME, AUTH_TOKEN)
report_portal.create_project

total_finish_launches = 0
puts "START\n------\n"
client.query('SELECT * '\
             'FROM test_run '\
             'ORDER BY UNIX_TIMESTAMP(start_time) '\
             "DESC LIMIT #{TEST_RUN_COUNT}").each do |test_run|
  launch = report_portal.start_launch(
    MaxScaleReportPortal.launch_name(test_run),
    'DEFAULT',
    MaxScaleReportPortal.description(REPOSITORY_URL, LOGS_DIR_URL, test_run),
    MaxScaleReportPortal.start_time(test_run),
    MaxScaleReportPortal.launch_tags(test_run)
  )

  max_test_time = 0.0
  client.query('SELECT * '\
               'FROM results '\
               "WHERE id = #{test_run['id']}").each do |test_result|
    report_portal.add_root_test_item(
      launch,
      test_result['test'],
      MaxScaleReportPortal.description(REPOSITORY_URL, LOGS_DIR_URL,
                                       test_run, test_result),
      [],
      MaxScaleReportPortal.start_time(test_run),
      'TEST',
      MaxScaleReportPortal.test_tags(test_run, test_result),
      MaxScaleReportPortal.test_result_status(test_result),
      MaxScaleReportPortal.end_time(test_run, test_result['test_time'])
    )
    max_test_time = test_result['test_time'].to_f if test_result['test_time'].to_f > max_test_time
  end

  report_portal.finish_launch(launch, MaxScaleReportPortal.end_time(test_run, max_test_time))
  total_finish_launches += 1
  puts "Number of TestRun added: #{total_finish_launches}/#{TEST_RUN_COUNT}"
end
puts "\n------\nFINISH"
