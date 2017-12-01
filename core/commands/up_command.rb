# frozen_string_literal: true

require_relative 'base_command'

# The command sets up the environment specified in the configuration file.
class UpCommand < BaseCommand
  def self.synopsis
    'Setup environment as specified in the configuration'
  end

  def setup_command
    if @args.empty? || @args.first.nil?
      @ui.warning 'You must specify path to the mdbci configuration as a parameter.'
      return false
    end
    @configuration = @args.first

    @attempts = if @env.attempts.nil?
                  5
                else
                  @env.attempts.to_i
                end
    true
  end

  def execute
    return ARGUMENT_ERROR_RESULT unless setup_command

    # Saving dir, do then to change it back
    pwd = Dir.pwd

    # Separating config_path from node
    config = []
    node = ''
    up_type = false # Means no node specified
    paths = @configuration.split('/') # Get array of dirs
    # Get path to vagrant instance directory
    config_path = paths[0, paths.length - 1].join('/')
    if !config_path.empty?
      # So there may be node specified
      node = paths[paths.length - 1]
      config[0] = config_path
      config[1] = node
      up_type = true # Node specified
    else
      config_path = paths[0, paths.length].join('/')
    end

    # Checking if vagrant instance derictory exists
    if Dir.exist?(config[0].to_s) # to_s in case of 'nil'
      up_type = true # node specified
      @ui.info 'Node is specified ' + config[1] + ' in ' + config[0]
    else
      up_type = false # node not specified
      @ui.info 'Node isn\'t specified in ' + @configuration
    end

    template = JSON.parse(File.read(File.read("#{up_type ? config[0] : @configuration}/template")))

    up_type ? Dir.chdir(config[0]) : Dir.chdir(@configuration)

    # Setting provider: VBox, AWS, Libvirt, Docker
    begin
      @nodesProvider = File.read('provider')
    rescue
      raise 'File with provider info not found'
    end

    @ui.info 'Current provider: ' + @nodesProvider

    if @nodesProvider == 'mdbci'
      @ui.warning 'You are using mdbci nodes template. ./mdbci up command doesn\'t supported for this boxes!'
      return 1
    else
      # Generating docker images (so it will not be loaded for similar nodes repeatedly)
      generateDockerImages(template, '.') if @nodesProvider == 'docker'

      no_parallel_flag = ''
      if (@nodesProvider == 'aws') || (@nodesProvider == 'docker')
        no_parallel_flag = " #{VAGRANT_NO_PARALLEL} "
      end

      @ui.info "Bringing up #{(up_type ? 'node ' : 'configuration ')} #{@configuration}"

      @ui.info 'Destroying everything'
      cmd_destr = 'vagrant destroy --force ' + (up_type ? config[1] : '')
      exec_cmd_destr = `#{cmd_destr}`
      @ui.info exec_cmd_destr

      cmd_up = "vagrant up #{no_parallel_flag} --provider=#{@nodesProvider} #{(up_type ? config[1] : '')}"
      @ui.info "Actual command: #{cmd_up}"
      chef_not_found_node = nil
      status = nil
      begin
        chef_not_found_node = nil
        status = Open3.popen3(cmd_up) do |stdin, stdout, stderr, wthr|
          stdin.close
          stdout.each_line do |line|
            @ui.info line
            chef_not_found_node = line if @nodesProvider == 'aws'
          end
          stdout.close
          error = stderr.read
          stderr.close
          if (@nodesProvider == 'aws') && error.to_s.include?(CHEF_NOT_FOUND_ERROR)
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
              cmd_up = "vagrant up #{no_parallel_flag} --provider=#{@nodesProvider} #{machine}"
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
                cmd_up = "vagrant up #{no_parallel_flag} --provider=#{@nodesProvider} #{machine}"
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
    end
    @ui.info 'All nodes successfully up!'
    @ui.info "DIR_PWD=#{pwd}"
    @ui.info "CONF_PATH=#{config_path}"
    Dir.chdir pwd
    @ui.info "Generating #{config_path}_network_settings file"
    if up_type == false
      printConfigurationNetworkInfoToFile(config_path)
    else
      printConfigurationNetworkInfoToFile(config_path, node)
    end
    SUCCESS_RESULT
  end

  # Checks that all required parameters are passed to the command
  # and set them as instance variables.
  #
  # @return [Boolean] false if unable to setup command.

end
