#!/usr/bin/env ruby
# frozen_string_literal: true

# Class for log-file parsing
class LogParser
  attr_reader :cmake_flags, :maxscale_source, :target, :mariadb_version, :box,
              :logs_dir

  def parse_ctest_log(log)
    cmake_flags_regex = /CMake flags:\s+(.+)/
    maxscale_source_regex = /Source:\s+(.+)/
    box_regex = /\{"hostname"=>".*"\, "box"=>"(\w+)"/
    box_regex_2 = /box=(\w+)/
    mariadb_version_regex = /"product"=>\{"name"=>"mariadb", "version"=>"(\d+\.\d+)"/
    target_regex = /mdbci called with: \["generate", "(.+)"\]/
    logs_dir_regex = /^Logs go to \/home\/vagrant\/LOGS\/(.+)$/

    @cmake_flags = nil
    @maxscale_source = nil
    @target = nil
    @mariadb_version = nil
    @box = nil
    @logs_dir = nil

    log.each_line do |line|
      @logs_dir = extract_value_from_str(line, logs_dir_regex) if @logs_dir.nil?
      @box = extract_value_from_str(line, box_regex) if @box.nil?
      @box = extract_value_from_str(line, box_regex_2) if @box.nil?
      @mariadb_version = extract_value_from_str(line, mariadb_version_regex) if @mariadb_version.nil?
      @target = extract_value_from_str(line, target_regex) if @target.nil?
      @cmake_flags = extract_value_from_str(line, cmake_flags_regex) if @cmake_flags.nil?
      @maxscale_source = extract_value_from_str(line, maxscale_source_regex) if @maxscale_source.nil?

      if !@maxscale_source.nil? && !@cmake_flags.nil? &&
         !@box.nil? && !@mariadb_version.nil? && !@target.nil? &&
         !@logs_dir.nil?
        break
      end
    end
  end

  private

  def extract_value_from_str(line, regex)
    if line =~ regex
      line.match(regex).captures[0].strip
    else
      nil
    end
  end
end

if ARGV.length != 3
  puts <<-EOF
  Usage:
    load_logs USER PASSWORD LOGS_DIR

    USER: The database username.
    PASSWORD: The database password.
    LOGS_DIR: The directory with logs.
    EOF
  exit 0
end

USER = ARGV.shift
PASSWORD = ARGV.shift
LOGS_DIR = ARGV.shift.chomp('"').reverse.chomp('"').reverse

HOST = 'localhost'
PORT = '3306'
DB_NAME = 'test_results_db'

require 'mysql2'

begin
  client = Mysql2::Client.new(
    :host => HOST,
    :port => PORT,
    :username => USER,
    :password => PASSWORD,
    :database => DB_NAME
  )
rescue Mysql2::Error => e
  puts e.message
  exit 1
end

Dir.glob("#{LOGS_DIR}/run_test*").select do |fn|
  next unless File.directory?(fn)

  Dir.glob("#{fn}/build_log*") do |build_log|
    log = File.read build_log
    log = log.encode('UTF-16be', :invalid => :replace).encode('UTF-8')

    parser = LogParser.new
    parser.parse_ctest_log(log)
    jenkins_id = build_log.match(/build_log_(\d+)/).captures[0].strip

    # Add information about logs_dir
    client.query("UPDATE test_run SET logs_dir='#{parser.logs_dir}' WHERE jenkins_id='#{jenkins_id}'")

    # Add information about maxscale_source and cmake_flags
    build_count = client.query("SELECT COUNT(*) as count FROM test_run WHERE jenkins_id='#{jenkins_id}'").first['count']
    if build_count == 1
      client.query("UPDATE test_run SET maxscale_source='#{parser.maxscale_source}', cmake_flags='#{parser.cmake_flags}' "\
      "WHERE jenkins_id='#{jenkins_id}'")
    elsif build_count > 1
      client.query("UPDATE test_run SET maxscale_source='#{parser.maxscale_source}', cmake_flags='#{parser.cmake_flags}' "\
      "WHERE box='#{parser.box}' AND target='#{parser.target}' AND mariadb_version='#{parser.mariadb_version}' "\
      "AND jenkins_id='#{jenkins_id}'")
    else
      next
    end

    puts "Update TestRun with jenkins_id=#{jenkins_id}"
  end
end
