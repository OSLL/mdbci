# frozen_string_literal: true

require_relative '../../services/shell_commands'
require_relative '../../models/return_codes'
require_relative '../../models/network_settings'

# The configurator that is able to bring up the Docker swarm cluster
class DockerSwarmConfigurator
  include ReturnCodes
  include ShellCommands

  def initialize(config, env, logger)
    @config = config
    @ui = logger
    @attempts = env.attempts&.to_i || 5
  end

  def configure
    @ui.info('Bringing up docker nodes')
    return SUCCESS_RESULT unless @config.docker_configuration?

    extract_node_configuration
    if @configuration['services'].empty?
      @ui.info('No Docker services are configured to be brought up')
      return SUCCESS_RESULT
    end
    result = bring_up_nodes
    return result unless result == SUCCESS_RESULT

    result = wait_for_services
    return result unless result == SUCCESS_RESULT

    store_network_settings
  end

  # Extract only the required node configuration from the whole configuration
  # @return [Hash] the Swarm configuration that should be brought up
  def extract_node_configuration
    @ui.info('Selecting Docker Swarm services to be brought up')
    node_names = @config.node_names
    @configuration = @config.docker_configuration
    @configuration['services'].select! do |service_name, _|
      node_names.include?(service_name)
    end
  end

  # Create the extract of the services that must be brought up and
  # deploy the new configuration to the stack, record the service ids
  def bring_up_nodes
    @ui.info('Bringing up the Docker Swarm stack')
    config_file = @config.docker_partial_configuration
    File.write(config_file, YAML.dump(@configuration))
    result = bring_up_docker_stack(config_file)
    return result unless result == SUCCESS_RESULT

    result = run_command("docker stack ps --format '{{.ID}}' #{@config.name}")
    unless result[:value].success?
      @ui.error('Unable to get the list of tasks')
      return ERROR_RESULT
    end
    @tasks = result[:output].each_line.map { |task_id| { task_id: task_id } }
    SUCCESS_RESULT
  end

  # Bring up the stack, perform it several times if necessary
  def bring_up_docker_stack(config_file)
    (@attempts + 1).times do
      result = run_command_and_log("docker stack deploy -c #{config_file} #{@config.name}")
      return SUCCESS_RESULT if result[:value].success?

      @ui.error('Unable to deploy the docker stack!')
      sleep(1)
    end
    ERROR_RESULT
  end

  # Wait for services to start and acquire the IP-address
  def wait_for_services
    @ui.info('Waiting for stack services to become ready')
    60.times do
      @tasks.each do |task|
        next if task.key?(:ip_address)

        status, task_info = get_task_information(task[:task_id])
        return ERROR_RESULT if status == ERROR_RESULT

        task.merge!(task_info) if status == SUCCESS_RESULT
      end
      return SUCCESS_RESULT if @tasks.all? { |task| task.key?(:ip_address) }

      sleep(1)
    end
    ERROR_RESULT
  end

  # Get the IP address for the task
  # @param task_id [String] the task to get the IP address for
  def get_task_information(task_id)
    result = run_command("docker inspect #{task_id}")
    unless result[:value].success?
      @ui.error('Unable to get information about the service')
      return ERROR_RESULT, ''
    end
    task_data = JSON.parse(result[:output])[0]
    if task_data['Status']['State'] == 'running'
      process_task_data(task_data)
    else
      [NO_RESULT, '']
    end
  end

  # Convert task description into correct description, get all required ip addresses
  def process_task_data(task_data)
    private_ip_address = task_data['NetworksAttachments'][0]['Addresses'][0].split('/')[0]

    result, ip_address = get_service_public_ip(task_data['Status']['ContainerStatus']['ContainerID'],
                                               private_ip_address)
    return ERROR_RESULT, '' if result == ERROR_RESULT

    task_info = {
      ip_address: ip_address,
      private_ip_address: private_ip_address,
      node_name: task_data['Spec']['Networks'][0]['Aliases'][0]
    }
    [SUCCESS_RESULT, task_info]
  end

  # Get the ip address of the docker swarm service that is located on the current machine
  # @param container_id [String] the name of the container to get data from
  # @param private_ip_address [String] the private IP address
  def get_service_public_ip(container_id, private_ip_address)
    result = run_command("docker exec #{container_id} ip address")
    unless result[:value].success?
      @ui.error("Unable to determine the IP address of the container #{container_id}")
      return ERROR_RESULT, ''
    end

    result[:output].each_line do |full_line|
      line = full_line.strip
      next unless line.start_with?('inet')

      possible_addr = line.split(/\s+/)[1].split('/')[0]
      next if ['127.0.0.1', private_ip_address].include?(possible_addr)

      return [SUCCESS_RESULT, possible_addr]
    end

    [ERROR_RESULT, '']
  end

  # Put the network settings information into the files
  def store_network_settings
    @ui.info('Generating network configuration file')
    network_settings = NetworkSettings.new
    @tasks.each do |task|
      network_settings.add_network_configuration(task[:node_name], 'private_ip' => task[:private_ip_address],
                                                                   'network' => task[:ip_address])
    end
    network_settings.store_network_configuration(@config)
  end
end
