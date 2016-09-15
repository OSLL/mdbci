#!/usr/bin/env ruby

require 'getoptlong'
require 'json'

INPUT_FILE_OPTION = '--input-file'
ENV_FILE_OPTION = '--env-file'
SILENT_OPTION = '--silent'
HELP_OPTION = '--help'
DB_WRITE_STATUS = 'DB_WRITE_STATUS'
DB_WRITE_STATUS_SUCCESS = 'Data stored successfuly'

def parse_cmd_args
  opts = GetoptLong.new(
      [INPUT_FILE_OPTION, '-i', GetoptLong::REQUIRED_ARGUMENT],
      [ENV_FILE_OPTION, '-e', GetoptLong::REQUIRED_ARGUMENT],
      [SILENT_OPTION, '-s', GetoptLong::OPTIONAL_ARGUMENT],
      [HELP_OPTION, '-h', GetoptLong::OPTIONAL_ARGUMENT]
  )

  options = {}
  opts.each do |opt, arg|
    case opt
      when INPUT_FILE_OPTION
        options[:input_file] = arg
      when ENV_FILE_OPTION
        options[:env_file] = arg
      when SILENT_OPTION
        options[:silent] = true
      when HELP_OPTION
        puts <<-EOT
  Benchmark parser usage:
      write_benchmark_results -i JSON_FILE -e env_file [ -s ]
          [ -i ]                - input json file
          [ -e ]                - env file to create or append
          [ -h ]                - SHOW HELP
        EOT
        exit 0
    end
  end
  if !options.key?(:input_file) or !options.key?(:env_file)
    puts "Not enough arguments. Try -h for help."
    exit 1
  end

  unless File.file?(options[:input_file])
    puts "#{options[:input_file]} does not exist!"
    exit 1
  end

  return options
end

def parse_json_file(input_file)
  puts "parse_json_file #{input_file}"
  file = File.read(input_file)
  hash = JSON.parse(file)
  return hash
end

def write_to_performance_test_run(hash)
  puts "write_to_performance_test_run"
end

def write_to_maxscale_parameters(hash, id)
  puts "write_to_maxscale_parameters"
end

def write_to_sysbench_results(hash, id)
  puts "write_to_sysbench_results"
end


def write_results_to_db(hash)
  puts "write_results_to_db #{hash}"
  db_write_status = DB_WRITE_STATUS_SUCCESS 
  begin 
    id = write_to_performance_test_run(hash)
    write_to_maxscale_parameters(hash, id)
    write_to_sysbench_results(hash, id)
  rescue => e
    db_write_status = "Error during writing to DB, #{e.message}" 
    puts db_write_status
  end
end

def write_db_result_to_env_file(db_write_status, env_file)
  puts "write_db_result_to_env_file #{db_write_status}, #{env_file}"
  db_editing_env_var = "#{DB_WRITE_STATUS}=#{db_write_status}"
  File.open(env_file, 'a') do |f|
    f.puts db_editing_env_var
  end
end



def main
  options = parse_cmd_args
  hash = parse_json_file(options[:input_file])
  db_write_status = write_results_to_db(hash)
  write_db_result_to_env_file(db_write_status, options[:env_file])

  puts "Writing results to db completed!"
end

if File.identical?(__FILE__, $0)
  main
end
