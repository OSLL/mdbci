# Module for information formatting
module MaxScaleReportPortal
  require 'date'

  def self.commit_url(repository_url, commit_id)
    return '#' if commit_id.nil? || commit_id.strip.length != 40
    "#{repository_url}/commit/#{commit_id}"
  end

  def self.logs_url(logs_dir_url, logs_dir, test_name = nil)
    return '#' if logs_dir.nil? || logs_dir.strip.empty?
    url = "#{logs_dir_url}/#{logs_dir}"
    url += "/LOGS/#{test_name}" unless test_name.nil?
    url
  end

  def self.launch_name(test_run)
    "TestRun ##{test_run['jenkins_id']}"
  end

  def self.description(repository_url, logs_dir_url, test_run, test_name = nil)
    "**Target:** #{test_run['target']}\n"\
        "**Box:** #{test_run['box']}\n"\
        "**Product:** #{test_run['product']}\n"\
        "**MariaDB version:** #{test_run['mariadb_version']}\n"\
        "**MaxScale commit:** #{commit_markdown_link(repository_url, test_run['maxscale_commit_id'])}\n"\
        "**Test code commit:** #{test_run['test_code_commit_id']}\n"\
        "**Job name:** #{test_run['job_name']}\n"\
        "**CMake flags:** #{test_run['cmake_flags']}\n"\
        "**MaxScale source:** #{test_run['maxscale_source']}\n"\
        "**Logs directory:** #{logs_markdown_link(logs_dir_url, test_run['logs_dir'], test_name)}"
  end

  def self.start_time(test_run)
    datetime(test_run['start_time'])
  end

  def self.end_time(test_run)
    start_time(test_run)
  end

  def self.launch_tags(test_run)
    [
      test_run['box'],
      test_run['product'],
      "ver:#{test_run['mariadb_version']}",
      "maxscale:#{test_run['maxscale_source']}",
      "target:#{test_run['target']}"
    ] + tags_from_target(test_run['target'])
  end

  def self.tags_from_target(target)
    if !target.nil? && target.include?('daily')
      ['daily']
    else
      []
    end
  end

  def self.test_tags(test_run, _test_result)
    launch_tags(test_run)
  end

  def self.datetime(str)
    return DateTime.new(2011, 2, 3.5).strftime('%Y-%m-%dT%H:%M:%SZ') if str.nil?
    begin
      date_res = DateTime.parse(str.to_s).strftime('%Y-%m-%dT%H:%M:%SZ')
    rescue ArgumentError
      return DateTime.new(2001, 2, 3.5).strftime('%Y-%m-%dT%H:%M:%SZ')
    end
    date_res
  end

  def self.test_result_status(test_result)
    if test_result['result'].zero?
      'PASSED'
    else
      'FAILED'
    end
  end

  def self.commit_markdown_link(repository_url, commit_id)
    "[#{commit_id}](#{commit_url(repository_url, commit_id)})"
  end

  def self.logs_markdown_link(logs_dir_url, logs_dir, test_name = nil)
    "[#{logs_dir}](#{logs_url(logs_dir_url, logs_dir, test_name)})"
  end
end
