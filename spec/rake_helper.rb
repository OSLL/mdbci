PATH_TO_RSPEC_SPEC_FOLDER = 'spec/'

class RakeTaskManager

  attr_accessor :rspec_test_name
  attr_accessor :failed_tests
  attr_accessor :cmd

  @@failed_tests = Array.new

  def initialize(task_name)
    @rspec_test_name = PATH_TO_RSPEC_SPEC_FOLDER + task_name.to_s.split('_', 2)[1] + '_spec.rb'
  end

  def run
    # executing rspec test, capturing and streaming output
    @cmd = `rspec #{@rspec_test_name} 2>/dev/null`
    puts @cmd
  end

  def run_parametrized(arguments)
    if arguments != nil
      arguments.each { |key, value| puts key.to_s; puts value }
      # creating parameters for rspec test
      arguments.each { |key, value| ENV[key.to_s] = value }

      # run tests
      run

      # generating output of failed tests
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

      # removing parameter, test is over
      arguments.each { |key, _| ENV.delete(key.to_s) }
    end
  end

  def self.get_failed_tests_info
    if @@failed_tests.length == 0
      puts 'All tests passed'
    else
      puts 'Failed tests'
      @@failed_tests.each { |line| puts line}
    end
  end

end