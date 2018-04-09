#!/usr/bin/env ruby

require 'getoptlong'
require 'json'
require 'yaml'

INPUT_FILE_OPTION = '--input-file'
OUTPUT_FILE_OPTION = '--output-file'
ENV_FILE_OPTION = '--env-file'
SILENT_OPTION = '--silent'
HELP_OPTION = '--help'

SYSBENCH_BLOCK_START = "SQL statistics:\n"
# NEW_LINE_SYSBENCH_COUNT = 3
SYSBENCH_BLOCK_LINE_REGEX = /.*ssh:(.*\n)/
SYSBENCH_BLOCK_LAST_LINE = 'execution time (avg/stddev)'
SYSBENCH_RESULTS_RAW = 'SYSBENCH_RESULTS_RAW'

# MAXSCALE_COMMIT_REGEX = /MaxScale\s+.*\d+\.*\d*\.*\d*\s+-\s+(.+)/
MAXSCALE_SOURCE_REGEX = /MaxScale version: maxscale-(.*)/
SYSBENCH_VERSION_REGEX = /DEBUG: ssh: sysbench (.*) \(/

BUILD_PARAMS = 'build_params'
BENCHMARK_RESULTS = 'benchmark_results'

$maxscale_commit = nil
$maxscale_source = nil
$test_tool_version = nil

def parse_cmd_args
  opts = GetoptLong.new(
      [INPUT_FILE_OPTION, '-i', GetoptLong::REQUIRED_ARGUMENT],
      [OUTPUT_FILE_OPTION, '-o', GetoptLong::REQUIRED_ARGUMENT],
      [ENV_FILE_OPTION, '-e', GetoptLong::REQUIRED_ARGUMENT],
      [SILENT_OPTION, '-s', GetoptLong::OPTIONAL_ARGUMENT],
      [HELP_OPTION, '-h', GetoptLong::OPTIONAL_ARGUMENT]
  )

  options = {}
  opts.each do |opt, arg|
    case opt
      when INPUT_FILE_OPTION
        options[:input_file] = arg
      when OUTPUT_FILE_OPTION
        options[:output_file] = arg
      when ENV_FILE_OPTION
        options[:env_file] = arg
      when SILENT_OPTION
        options[:silent] = true
      when HELP_OPTION
        puts <<-EOT
  Benchmark parser usage:
      parse_log -i LOG_FILE_PATH -o JSON_FILE -e env_file [ -s ]
          [ -i ]                - input log
          [ -o ]                - output json file
          [ -e ]                - env file to create or append
          [ -h ]                - SHOW HELP
        EOT
        exit 0
    end
  end
  if !options.key?(:input_file) or !options.key?(:output_file) or !options.key?(:env_file)
    puts "Not enough arguments. Try -h for help."
    exit 1
  end

  unless File.file?(options[:input_file])
    puts "#{options[:input_file]} does not exist!"
    exit 1
  end

  return options
end

def extract_sysbench_results_raw(input_file)
  sysbench_results_raw = ''
  sysbench_block_found = false
  new_line_count = 0
  File.open(input_file, "r") do |f|
    f.each_line do |line|
      line = line.force_encoding("ISO-8859-1").encode("UTF-8")
      # if line =~ MAXSCALE_COMMIT_REGEX and $maxscale_commit == nil
      #   $maxscale_commit = line.match(MAXSCALE_COMMIT_REGEX).captures[0]
      # end
      if line =~ MAXSCALE_SOURCE_REGEX and $maxscale_source.nil?
        $maxscale_source = line.match(MAXSCALE_SOURCE_REGEX).captures[0]
      end
      if line =~ SYSBENCH_VERSION_REGEX and $test_tool_version.nil?
        $test_tool_version = line.match(SYSBENCH_VERSION_REGEX).captures[0]
      end
      if line.include?(SYSBENCH_BLOCK_START)
        puts "Found start of sysbench block"
        sysbench_block_found = true
      end

      if sysbench_block_found
        if line =~ SYSBENCH_BLOCK_LINE_REGEX
          line = line.match(SYSBENCH_BLOCK_LINE_REGEX).captures[0]
        end
        sysbench_results_raw += line

        if line.include?(SYSBENCH_BLOCK_LAST_LINE)
          puts "Read all sysbench_results_raw"
          return sysbench_results_raw
        end
      end

    end
  end

  if sysbench_results_raw == ''
    raise "sysbench_results_raw not found"
  end
  return sysbench_results_raw
end

def write_sysbench_results_to_env_file(sysbench_results_raw, env_file)
  # Adding \ at the end of each line to avoid losing multiline env variable
  sysbench_results_raw_ = sysbench_results_raw.gsub("\n", " \\\n")
  # Removing last \
  sysbench_results_raw_ = sysbench_results_raw_[0..-3]

  sysbench_results_raw_ = "#{SYSBENCH_RESULTS_RAW} \\\n#{sysbench_results_raw_}"
  File.open(env_file, 'w') do |f|
    f.puts sysbench_results_raw_
  end
end

def parse_sysbench_results_raw(sysbench_results_raw)
  return YAML.load(sysbench_results_raw)
end

def flatten_keys(hash, temp_hash = nil, new_hash = nil)
  new_hash = Hash.new if new_hash.nil?
  temp_hash = Hash.new if temp_hash.nil?
  unless hash.is_a? Hash
    new_hash[temp_hash] = hash
    return
  end
  hash.each do |el|
    next_element = el[0].gsub(/\s+/, '_')
    next_element.gsub!('.', '_')
    next_temp_hash = temp_hash.empty? ? next_element : "#{temp_hash}_#{next_element}"
    flatten_keys(el[1], next_temp_hash, new_hash)
  end
  return new_hash
end

def clean_values(hash)
  hash.each do |key, value|
    next if !value.is_a? String

    new_value = value.gsub(/[a-zA-Z]+/,"")
    new_value = new_value.gsub(/([^\s]+)\s+.+$/, '\1')
    hash[key] = new_value.to_f
  end
  return hash
end


def split_slash_keys(hash)
  slash_keys = []
  hash.each do |key, value|
    slash_keys.push(key) if value.is_a? String and value.include? '/'
  end
  slash_keys.each do |key|
    value = hash[key]
    sub_keys = key.gsub(/.*\(([^\)]+)\)/, '\1').split('/')
    sub_values = value.split('/')
    base_key = key.gsub(/\(.*$/,"")

    hash.delete key
    (0..1).each do |i|
      hash[base_key+sub_keys[i]] = sub_values[i]
    end
  end

  return hash
end

def remove_slashes_from_keys(hash)
  slash_keys = []
  hash.each do |key, value|
    slash_keys.push(key) if key.is_a? String and key.include? '/'
  end

  slash_keys.each do |key|
    new_key = key.gsub('/', '_')
    hash[new_key] = hash.delete key
  end

  return hash

end

def get_test_code_commit
  return 'NOT FOUND' if ENV['WORKSPACE'].nil?
  current_directory = Dir.pwd
  Dir.chdir ENV['WORKSPACE']
  git_log = `git log -1`
  Dir.chdir current_directory
  return 'NOT FOUND' if git_log.nil?
  commit_regex = /commit\s+(.+)/
  if git_log.lines.first =~ commit_regex
    return git_log.lines.first.match(commit_regex).captures[0]
  end
  return 'NOT FOUND'
end

def get_build_params_hash
  template_path = ENV['name'] ? "#{ENV['HOME']}/mdbci/#{ENV['name']}.json" : 'NOT FOUND'
  cnf_path = File.exist?('maxscale.cnf') ? "#{Dir.pwd}/maxscale.cnf" : 'NOT FOUND'
  return {
      'jenkins_id' => ENV['BUILD_NUMBER'] || 'NOT FOUND',
      'start_time' => ENV['BUILD_TIMESTAMP'] || 'NOT FOUND',
      'box' => ENV['box'] || 'NOT FOUND',
      'product' => ENV['product'] || 'NOT FOUND',
      'mariadb_version' => ENV['version'] || 'NOT FOUND',
      'test_code_commit_id' => get_test_code_commit,
      'product_under_test' => 'maxscale',
      'job_name' => ENV['JOB_NAME'] || 'NOT FOUND',
      'machine_count' => ENV['machines_count'] || 'NOT FOUND',
      'sysbench_params' => ENV['sysbench_params'] || 'NOT FOUND',
      'mdbci_template' => template_path,
      'test_tool' => 'sysbench',
      'target' => ENV['target'] || 'NOT FOUND',
      'maxscale_commit_id' => $maxscale_commit || 'NOT FOUND',
      'maxscale_cnf' => cnf_path,
      'maxscale_source' => $maxscale_source || 'NOT FOUND',
      'test_tool_version' => $test_tool_version || 'NOT FOUND'
  }
end

# Update the hash with values extracted from the build log
CONFIG_PARAMS = {
  'MariaDB version:' => 'mariadb_version',
  'MaxScale configuration:' => 'maxscale_cnf',
  'Source:' => 'maxscale_source',
  'MaxScale .* -' => 'maxscale_commit_id',
}
def update_build_params_hash_with_build_log(hash, log_path)
  File.readlines(log_path).each do |line|
    CONFIG_PARAMS.each do |pattern, key|
      data = line.match(/\s*#{pattern}\s*(.*)\s*/)
      next unless data
      hash[key] = data[1].strip
    end
  end
end

def write_hash_to_json(hash, output_file)
  File.open(output_file,"w") do |f|
    f.write(hash.to_json)
  end
end

def main
  options = parse_cmd_args
  sysbench_results_raw = extract_sysbench_results_raw(options[:input_file])
  write_sysbench_results_to_env_file(sysbench_results_raw, options[:env_file])
  hash = parse_sysbench_results_raw(sysbench_results_raw)
  hash = flatten_keys(hash)
  hash = split_slash_keys(hash)
  hash = clean_values(hash)
  hash = remove_slashes_from_keys(hash)
  build_params_hash = get_build_params_hash
  update_build_params_hash_with_build_log(build_params_hash, options[:input_file])
  result = { BUILD_PARAMS => build_params_hash, BENCHMARK_RESULTS => hash}
  write_hash_to_json(result, options[:output_file])

  puts "Parsing completed!"
end

if File.identical?(__FILE__, $0)
  main
end
