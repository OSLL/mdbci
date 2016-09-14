#!/usr/bin/env ruby

require 'getoptlong'
require 'json'
require 'yaml'

INPUT_FILE_OPTION = '--input-file'
OUTPUT_FILE_OPTION = '--output-file'
ENV_FILE_OPTION = '--env-file'
SILENT_OPTION = '--silent'
HELP_OPTION = '--help'

SYSBENCH_BLOCK_START = "OLTP test statistics:\n"
NEW_LINE_SYSBENCH_COUNT = 3
SYSBENCH_RESULTS_RAW = 'SYSBENCH_RESULTS_RAW'

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
    next_element = process_characters(el[0])
    next_temp_hash = temp_hash.empty? ? next_element : "#{temp_hash}.#{next_element}"
    flatten_keys(el[1], next_temp_hash, new_hash)
  end
  return new_hash
end

def process_characters(characters)
  characters = characters.downcase
  characters = characters.gsub(/[.*|\/\\\s]+/, '_')
  characters = characters.gsub(/[()]+/, '')
  return characters
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
