PATH_TO_RSPEC_SPEC_FOLDER = 'spec/'

class RakeTaskManager

  attr_accessor :rspec_test_name
  attr_accessor :failed_tests
  attr_accessor :cmd

  @@failed_tests = Array.new

  def initialize(task_name)
    @rspec_test_name = PATH_TO_RSPEC_SPEC_FOLDER + task_name.to_s.split('_', 2)[1] + '_spec.rb'
  end

  def generate_and_expand_output
    match_regular_expression = 'Failed examples:'
    match_line_found = false
    @cmd.each_line do |line|
      if !match_line_found
        if line =~ /#{match_regular_expression}/
          match_line_found = true
        end
      else
        unless line == "\n"
          @@failed_tests.push(line)
        end
      end
    end
  end

  # executing rspec test, with cutting stderr application output
  def run
    @cmd = `rspec #{@rspec_test_name}`# 2>/dev/null``
    puts @cmd
  end

  # creating parameters for rspec test
  # run tests
  # generating output of failed tests
  # removing parameters, test is over
  def run_parametrized(arguments)
    # Strange, but arguments variable is not Hash
    # so it needs to be converted...
    if !Hash.try_convert(arguments).empty?
      arguments.each { |key, value| ENV[key.to_s] = value }
      run
      generate_and_expand_output
      arguments.each { |key, _| ENV.delete(key.to_s) }
    else
      raise "No arguments provided for #{@rspec_test_name}, fix and try again."
    end
  end

  def self.get_failed_tests_info
    if @@failed_tests.length == 0
      puts 'All tests passed'
    else
      puts 'Failed tests:'
      @@failed_tests.each { |line| puts line}
    end
  end

end