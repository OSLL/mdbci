require_relative '../scripts/parametrized_testing/parametrized_test_wrapper'

class RakeTaskManager

  PATH_TO_RSPEC_SPEC_FOLDER = 'spec/'
  PATH_TO_INTEGRATION_TESTS_FOLDER = 'integration/'
  PATH_TO_UNIT_TESTS_FOLDER = 'unit/'

  PARAMETRIZED_CONFIG_ENV_VAR_PREFIX = 'mdbci_param_conf'
  PARAMETRIZED_CONFIG_ENV_VAR_PREFIX_ORIGIN = 'mdbci_param_conf_origin'
  PARAMETRIZED_CONFIG_PREFIX = 'mdbci_param_test_clone'
  PARAMETRIZED_CONFIG_PREFIX_ORIGIN = 'mdbci_param_test'
  PARAMETRIZED_CONFIGS = {
      "#{PARAMETRIZED_CONFIG_ENV_VAR_PREFIX}_#{DOCKER}" => "#{PARAMETRIZED_CONFIG_PREFIX}_#{DOCKER}",
      "#{PARAMETRIZED_CONFIG_ENV_VAR_PREFIX}_#{LIBVIRT}" => "#{PARAMETRIZED_CONFIG_PREFIX}_#{LIBVIRT}",
      "#{PARAMETRIZED_CONFIG_ENV_VAR_PREFIX}_#{PPC}" => "#{PARAMETRIZED_CONFIG_PREFIX}_#{PPC_FROM_DOCKER}",
      "#{PARAMETRIZED_CONFIG_ENV_VAR_PREFIX_ORIGIN}_#{DOCKER}" => "#{PARAMETRIZED_CONFIG_PREFIX_ORIGIN}_#{DOCKER}",
      "#{PARAMETRIZED_CONFIG_ENV_VAR_PREFIX_ORIGIN}_#{LIBVIRT}" => "#{PARAMETRIZED_CONFIG_PREFIX_ORIGIN}_#{LIBVIRT}",
      "#{PARAMETRIZED_CONFIG_ENV_VAR_PREFIX_ORIGIN}_#{DOCKER_FOR_PPC}" => "#{PARAMETRIZED_CONFIG_PREFIX_ORIGIN}_#{DOCKER_FOR_PPC}"
  }

  attr_accessor :rspec_test_name
  attr_accessor :failed_tests
  attr_accessor :cmd
  attr_accessor :silent
  attr_accessor :tests_counter

  @@failed_tests = Array.new
  @@tests_counter = 0
  @@failed_tests_counter = 0

  def initialize(task_name)
    @silent = ENV['SILENT']
    if @silent.nil? || @silent == 'true'
      @silent = true
    elsif @silent == 'false'
      @silent = false
    end
    @rspec_test_name = task_name.to_s.split(':')[1].split('_', 2)[1] + '_spec.rb'
    @@tests_counter += 1
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
    @rspec_test_name = PATH_TO_RSPEC_SPEC_FOLDER + @rspec_test_name
    unless File.exists?("#{@rspec_test_name}")
      @@failed_tests.push("Test not exists: #{@rspec_test_name}")
      @@failed_tests_counter +=1
      return 1
    end
    @cmd = `rspec #{@rspec_test_name}`
    describe_test(@rspec_test_name, @cmd, $?.exitstatus)
    generate_and_expand_output
  end

  def describe_test(test_name, output, exit_code)
    status = '...OK'
    if exit_code != 0
      status = '...FAILED'
      @@failed_tests_counter += 1
    end
    puts "Running test: #{test_name} " + status
    if !@silent || status == '...FAILED'
      describe_test_output output
    end
  end

  def describe_test_output(output)
    match_regular_expression = 'Finished in'
    lines_counter = 0
    if output.include? match_regular_expression
      output.each_line do |line|
        if line =~ /#{match_regular_expression}/
          break
        end
        lines_counter += 1
      end
      puts output.split("\n")[0..lines_counter-1]
    end
  end

  def with_environment_variables(variables)
    variables.each { |key, value| ENV[key.to_s] = value }
    yield
    variables.each { |key, _| ENV.delete(key.to_s) }
  end

  def run_parametrized(arguments)
    with_environment_variables(PARAMETRIZED_CONFIGS) {
      begin
        ptw = ParametrizedTestWrapper.new
        ptw.prepare_clones(arguments)
        run
      ensure
        ptw.remove_clones(arguments)
      end
    }
  end

  def run_unit
    @rspec_test_name = PATH_TO_UNIT_TESTS_FOLDER + @rspec_test_name
    run
  end

  def run_unit_parametrized(arguments)
    @rspec_test_name = PATH_TO_UNIT_TESTS_FOLDER + @rspec_test_name
    run_parametrized arguments
  end

  def run_integration
    @rspec_test_name = PATH_TO_INTEGRATION_TESTS_FOLDER + @rspec_test_name
    run
  end

  def run_integration_parametrized(arguments)
    @rspec_test_name = PATH_TO_INTEGRATION_TESTS_FOLDER + @rspec_test_name
    run_parametrized arguments
  end

  def self.custom_task(*args, &block)
    Rake::Task.define_task(*args, &block)
  end

  def self.rake_finalize(namespace_name_symbol)
    namespace_name_all_tasks_sym = "#{namespace_name_symbol}_all".to_sym
    custom_task :task_show_tests_info do
      RakeTaskManager.get_failed_tests_info
    end
    custom_task namespace_name_all_tasks_sym do
      Rake.application.in_namespace(namespace_name_symbol) do |x|
        x.tasks.each do |t|
          t.invoke
        end
      end
    end
    current_tasks = Rake.application.top_level_tasks
    current_tasks << :task_show_tests_info
    Rake.application.instance_variable_set(:@top_level_tasks, current_tasks)
  end

  def self.get_failed_tests_info
    if @@failed_tests.length == 0
      puts "\nAll tests passed #{@@tests_counter}/#{@@tests_counter}"
      exit 0
    else
      puts "\nFailed tests #{@@failed_tests_counter}/#{@@tests_counter}:"
      @@failed_tests.each { |line| puts line }
      exit 1
    end
  end

end