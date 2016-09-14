#!/usr/bin/env ruby

require 'getoptlong'
require 'json'

INPUT_FILE_OPTION = '--input-file'
OUTPUT_FILE_OPTION = '--output-file'
ENV_FILE_OPTION = '--env-file'
SILENT_OPTION = '--silent'
HELP_OPTION = '--help'

SYSBENCH_BLOCK_START = "OLTP test statistics:\n"
NEW_LINE_SYSBENCH_COUNT = 3
SYSBENCH_RESULTS_RAW = 'SYSBENCH_RESULTS_RAW'

MAXSCALE_COMMIT_REGEX = /MaxScale\s+.*\d+\.*\d*\.*\d*\s+-\s+(.+)/

$maxscale_commit = nil

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
      if line =~ MAXSCALE_COMMIT_REGEX and $maxscale_commit == nil
        $maxscale_commit = line.match(MAXSCALE_COMMIT_REGEX).captures[0]
      end
      if line == SYSBENCH_BLOCK_START
        puts "Found start of sysbench block"
        sysbench_block_found = true
      end

      if sysbench_block_found
        sysbench_results_raw += line
        if line == "\n"
          new_line_count+=1
        end

        if new_line_count == NEW_LINE_SYSBENCH_COUNT
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
  sysbench_results_raw.gsub!("\n", " \\\n")
  # Removing last \
  sysbench_results_raw = sysbench_results_raw[0..-3]

  sysbench_results_raw = "#{SYSBENCH_RESULTS_RAW} \\\n#{sysbench_results_raw}"
  File.open(env_file, 'w') do |f|
    f.puts sysbench_results_raw
  end
end

def parse_sysbench_results_raw(sysbench_results_raw)
end

def flatten_keys(hash)
end

def remove_brackets(hash)
end

def remove_units(hash)
end

def split_slash_keys(hash)
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

def get_build_params_hash
  provider = File.read("#{ENV['name']}/provider")
  template_name = provider == 'MDBCI' ? 'mdbci_template' : 'template'
  return {
      'jenkins_id' => ENV['BUILD_NUMBER'],
      'start_time' => ENV['BUILD_TIMESTAMP'],
      'box' => ENV['box'],
      'product' => ENV['product'],
      'mariadb_version' => ENV['version'],
      'test_code_commit_id' => get_test_code_commit,
      'product_under_test' => 'maxscale',
      'job_name' => ENV['JOB_NAME'],
      'machine_count' => ENV['machines_count'],
      'sysbench_params' => ENV['sysbench_params'],
      'mdbci_template' => File.read("#{ENV['name']}/#{template_name}"),
      'test_tool' => 'sysbench',
      'target' => ENV['target'],
      '$maxscale_commit_id' => $maxscale_commit,
      'maxscale_cnf' => `echo $(pwd)/maxscale.cnf`
  }
end

def write_hash_to_json(hash, output_file)
end

def main
  options = parse_cmd_args
  sysbench_results_raw = extract_sysbench_results_raw(options[:input_file])
  write_sysbench_results_to_env_file(sysbench_results_raw, options[:env_file])
  hash = parse_sysbench_results_raw(sysbench_results_raw)
  hash = flatten_keys(hash)
  hash = remove_brackets(hash)
  hash = remove_units(hash)
  hash = split_slash_keys(hash)
  hash = hash.merge get_build_params_hash
  write_hash_to_json(hash, options[:output_file])

  puts "Parsing completed!"
end

if File.identical?(__FILE__, $0)
  main
end
