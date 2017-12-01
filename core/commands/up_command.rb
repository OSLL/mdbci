# frozen_string_literal: true

require_relative 'base_command'

# The command sets up the environment specified in the configuration file.
class UpCommand < BaseCommand
  def self.synopsis
    'Setup environment as specified in the configuration'
  end

  # Checks that all required parameters are passed to the command
  # and set them as instance variables.
  #
  # @raise [ArgumentError] if unable to parse arguments.
  def setup_command
    if @args.empty? || @args.first.nil?
      raise ArgumentError, 'You must specify path to the mdbci configuration as a parameter.'
    end
    @configuration = @args.first

    @attempts = if @env.attempts.nil?
                  5
                else
                  @env.attempts.to_i
                end
    self
  end

  # Checks whether provided path is a directory containing configurations.
  #
  # @param path [String] path that should be checked
  #
  # @returns [Boolean]
  def configuration_directory?(path)
    !path.nil? &&
      !path.empty? &&
      Dir.exist?(path) &&
      File.exist?("#{path}/template") &&
      File.exist?("#{path}/provider") &&
      File.exist?("#{path}/Vagrantfile")
  end

  # Method parses up command configuration and extracts path to the
  # configuration and node name if specified.
  #
  # @raise [ArgumentError] if path to the configuration is invalid
  def parse_configuration
    # Separating config_path from node
    paths = @configuration.split('/') # Split path to the configuration
    config_path = paths[0, paths.length - 1].join('/')
    if configuration_directory?(config_path)
      node = paths.last
      @ui.info "Node #{node} is specified in #{config_path}"
    else
      node = ''
      config_path = @configuration
      @ui.info "Node is not specified in #{config_path}"
    end

    # Checking if vagrant instance derictory exists
    unless configuration_directory?(config_path)
      raise ArgumentError, "Specified path #{config_path} does not point to configuration directory"
    end
    [config_path, node]
  end

  def execute
    begin
      setup_command
      config_path, node = parse_configuration
    rescue ArgumentError => error
      @ui.warning error.message
      return ARGUMENT_ERROR_RESULT
    end

    # Saving dir, do then to change it back
    pwd = Dir.pwd
    Dir.chdir(config_path)

    template = JSON.parse(File.read(File.read('template')))

    # Setting provider: VBox, AWS, Libvirt, Docker
    begin
      nodes_provider = File.read('provider')
    rescue
      raise 'File with provider info not found'
    end

    @ui.info 'Current provider: ' + nodes_provider

    if nodes_provider == 'mdbci'
      @ui.warning 'You are using mdbci nodes template. ./mdbci up command doesn\'t supported for this boxes!'
      return ERROR_RESULT
    end

    # Generating docker images (so it will not be loaded for similar nodes repeatedly)
    generateDockerImages(template, '.') if nodes_provider == 'docker'

    no_parallel_flag = ''
    if (nodes_provider == 'aws') || (nodes_provider == 'docker')
      no_parallel_flag = " #{VAGRANT_NO_PARALLEL} "
    end

    @ui.info "Bringing up #{(node.empty? ? 'configuration ' : 'node ')} #{@configuration}"

    @ui.info 'Destroying everything'
    exec_cmd_destr = `vagrant destroy --force #{node}`
    @ui.info exec_cmd_destr

    cmd_up = "vagrant up #{no_parallel_flag} --provider=#{nodes_provider} #{node}"
    @ui.info "Actual command: #{cmd_up}"
    chef_not_found_node = nil
    status = nil
    begin
      chef_not_found_node = nil
      status = Open3.popen3(cmd_up) do |stdin, stdout, stderr, wthr|
        stdin.close
        stdout.each_line do |line|
          @ui.info line
          chef_not_found_node = line if nodes_provider == 'aws'
        end
        stdout.close
        error = stderr.read
        stderr.close
        if (nodes_provider == 'aws') && error.to_s.include?(CHEF_NOT_FOUND_ERROR)
          chef_not_found_node = chef_not_found_node.to_s.match(OUTPUT_NODE_NAME_REGEX).captures[0]
        else
          error.each_line { |line| @ui.error line }
          chef_not_found_node = nil
        end
        wthr.value
      end
      if chef_not_found_node
        @ui.warning "Chef not is found on aws node: #{chef_not_found_node}, applying quick fix..."
        cmd_provision = "vagrant provision #{chef_not_found_node}"
        status = Open3.popen3(cmd_provision) do |stdin, stdout, stderr, wthr|
          stdin.close
          stdout.each_line { |line| @ui.info line }
          stdout.close
          stderr.each_line { |line| @ui.error line }
          stderr.close
          wthr.value
        end
      end
    end while !chef_not_found_node.nil?
    unless status.success?
      @ui.error 'Bringing up failed'
      exit_code = status.exitstatus
      @ui.error "exit code #{exit_code}"

      dead_machines = []
      machines_with_broken_chef = []

      vagrant_status = `vagrant status`.split("\n\n")[1].split("\n")
      nodes = []
      vagrant_status.each { |stat| nodes.push(stat.split(/\s+/)[0]) }

      @ui.warning 'Checking for dead machines and checking Chef runs on machines'
      nodes.each do |machine_name|
        status = `vagrant status #{machine_name}`.split("\n")[2]
        @ui.info status
        unless status.include? 'running'
          dead_machines.push(machine_name)
          next
        end

        chef_log_cmd = "vagrant ssh #{machine_name} -c \"test -e /var/chef/cache/chef-stacktrace.out && printf 'FOUND' || printf 'NOT_FOUND'\""
        chef_log_out = `#{chef_log_cmd}`
        machines_with_broken_chef.push machine_name if chef_log_out == 'FOUND'
      end

      unless dead_machines.empty?
        @ui.error 'Some machines are dead:'
        dead_machines.each { |machine| @ui.error "\t#{machine}" }
      end

      unless machines_with_broken_chef.empty?
        @ui.error 'Some machines have broken Chef run:'
        machines_with_broken_chef.each { |machine| @ui.error "\t#{machine}" }
      end

      unless dead_machines.empty?
        (1..@attempts).each do |i|
          @ui.info 'Trying to force restart broken machines'
          @ui.info "Attempt: #{i}"
          dead_machines.delete_if do |machine|
            puts `vagrant destroy -f #{machine}`
            cmd_up = "vagrant up #{no_parallel_flag} --provider=#{nodes_provider} #{machine}"
            success = Open3.popen3(cmd_up) do |_stdin, stdout, stderr, wthr|
              stdout.each_line { |line| @ui.info line }
              stderr.each_line { |line| @ui.error line }
              wthr.value.success?
            end
            success
          end
          if !dead_machines.empty?
            @ui.error 'Some machines are still dead:'
            dead_machines.each { |machine| @ui.error "\t#{machine}" }
          else
            @ui.info 'All dead machines successfuly resurrected'
            break
          end
        end
        raise 'Bringing up failed (error description is above)' unless dead_machines.empty?
      end

      unless machines_with_broken_chef.empty?
        @ui.info 'Trying to re-provision machines'
        machines_with_broken_chef.delete_if do |machine|
          cmd_up = "vagrant provision #{machine}"
          success = Open3.popen3(cmd_up) do |_stdin, stdout, stderr, wthr|
            stdout.each_line { |line| @ui.info line }
            stderr.each_line { |line| @ui.error line }
            wthr.value.success?
          end
          success
        end
        unless machines_with_broken_chef.empty?
          @ui.error 'Some machines are still have broken Chef run:'
          machines_with_broken_chef.each { |machine| @ui.error "\t#{machine}" }
          (1..@attempts).each do |i|
            @ui.info 'Trying to force restart machines'
            @ui.info "Attempt: #{i}"
            machines_with_broken_chef.delete_if do |machine|
              puts `vagrant destroy -f #{machine}`
              cmd_up = "vagrant up #{no_parallel_flag} --provider=#{nodes_provider} #{machine}"
              success = Open3.popen3(cmd_up) do |_stdin, stdout, stderr, wthr|
                stdout.each_line { |line| @ui.info line }
                stderr.each_line { |line| @ui.error line }
                wthr.value.success?
              end
              success
            end
            if !machines_with_broken_chef.empty?
              @ui.error 'Some machines are still have broken Chef run:'
              machines_with_broken_chef.each { |machine| @ui.error "\t#{machine}" }
            else
              @ui.info 'All broken_chef machines successfuly reprovisioned.'
              break
            end
          end
          raise 'Bringing up failed (error description is above)' unless machines_with_broken_chef.empty?
        end
      end
    end

    @ui.info 'All nodes successfully up!'
    @ui.info "DIR_PWD=#{pwd}"
    @ui.info "CONF_PATH=#{config_path}"
    Dir.chdir pwd
    @ui.info "Generating #{config_path}_network_settings file"
    printConfigurationNetworkInfoToFile(config_path, node)
    SUCCESS_RESULT
  end
end
