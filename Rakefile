require 'rake'

PATH_TO_RSPEC_SPEC_FOLDER = 'spec/'

class TaskInitializer

  attr_accessor :rspec_test_name
  attr_accessor :failed_tests

  @@failed_tests = Array.new

  def initialize(task_name)
    @rspec_test_name = PATH_TO_RSPEC_SPEC_FOLDER + task_name.to_s.split('_', 2)[1] + '_spec.rb'
  end

  def run_parametrized(arguments)
    if arguments != nil
      arguments.each { |key, value| puts key.to_s; puts value }
      # creating parameters for rspec test
      arguments.each { |key, value| ENV[key.to_s] = value }

      # executing rspec test, capturing and streaming output
      cmd = `rspec #{@rspec_test_name}`
      puts cmd

      # generating output of failed tests
      match_regular_expression = 'Failed examples:'
      match_line_found = false
      cmd.each_line do |line|
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

  def run
    # executing rspec test, capturing and streaming output
    cmd = `rspec #{@rspec_test_name}`
    puts cmd
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

# name of task can not start with digits, so it starts with 'task...'

### EXAMPLE ###

# this task expecting argument which is hash {:pathToConfig=>'TEST', :vmType=>'mdbci'}
# keys and values will be added to ENV variable for one test then when test is executed
# those keys and values will be removed from ENV
task :task_6639_ssh_exit_code do |t, args|
  TaskInitializer.new(t).run_parametrized(args)
end


task :task_generator do |t|
  TaskInitializer.new(t).run
end

# here you need to add task with appropriate parameters
task :run_parametrized do
  Rake::Task[:task_6639_ssh_exit_code].execute({:pathToConfig=>'TEST', :vmType=>'mdbci'})
  TaskInitializer.get_failed_tests_info
end

task :run do
  Rake::Task[:task_generator].execute
  TaskInitializer.get_failed_tests_info
end
