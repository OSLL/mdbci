require 'rspec'
require_relative '../spec_helper'
require_relative '../../core/helper'

LOG_FILE = 'spec/configs/scripts/sysbench/sysbench_test_log'

ENV_FILE = 'spec/sysbench_test_env_file'

OUT_FILE = 'spec/sysbench_test_output_file'

test_command = './scripts/benchmark_parser/parse_log.rb'

describe 'test_spec' do

  after :all do
    FileUtils.rm ENV_FILE if File.exist? ENV_FILE
    FileUtils.rm OUT_FILE if File.exist? OUT_FILE
  end

  executeShellCommandsAndTestExitCode ([
      {'shell_command' => test_command, 'expectation' => 1},
      {'shell_command' => "#{test_command} -o #{OUT_FILE}", 'expectation' => 1},
      {'shell_command' => "#{test_command} -e #{ENV_FILE}", 'expectation' => 1},
      {'shell_command' => "#{test_command} -i #{LOG_FILE}", 'expectation' => 1},
      {'shell_command' => "#{test_command} -i #{LOG_FILE} -e #{ENV_FILE} -o #{OUT_FILE}", 'expectation' => 0}
  ])
end

