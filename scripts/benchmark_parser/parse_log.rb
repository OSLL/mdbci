#!/usr/bin/env ruby

require 'getoptlong'
require 'json'

INPUT_FILE_OPTION = '--input-file'
OUTPUT_FILE_OPTION = '--output-file'
ENV_FILE_OPTION = '--env-file'
SILENT_OPTION = '--silent'
HELP_OPTION = '--help'

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

  return options
end

def extract_sysbench_results_raw(input_file)
end

def write_sysbench_results_to_env_file(sysbench_results_raw, env_file)
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
  write_hash_to_json(hash, options[:output_file])
 
  puts "Parsing completed!" 
end

if File.identical?(__FILE__, $0)
  main
end
