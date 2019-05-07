# frozen_string_literal: true

require_relative '../../services/shell_commands'
require_relative '../../models/return_codes'

# The configurator that is able to bring up the Docker swarm cluster
class DockerSwarmConfigurator
  include ReturnCodes
  include ShellCommands

  def initialize(config, env, logger)
    @config = config
    @env = env
    @ui = logger
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

    wait_for_services
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
    result = run_command_and_log("docker stack deploy -c #{config_file} #{@config.name}")
    unless result[:value].success?
      @ui.error('Unable to deploy the docker stack!')
      return ERROR_RESULT
    end
    result = run_command("docker stack ps --format '{{.ID}}' #{@config.name}")
    unless result[:value].success?
      @ui.error('Unable to get the list of tasks')
      return ERROR_RESULT
    end
    @tasks = result[:output].each_line.map { |task_id| { task_id: task_id } }
    SUCCESS_RESULT
  end

  # Wait for services to start and acquire the IP-address
  def wait_for_services
    @ui.info('Waiting for stack services to become ready')
    10.times do
      @tasks.each do |task|
        next if task.key?(:ip_address)

        status, ip_address = get_task_ip_address(task[:task_id])
        return ERROR_RESULT if status == ERROR_RESULT

        task[:ip_address] = ip_address if status == SUCCESS_RESULT
      end
      return SUCCESS_RESULT if @tasks.all? { |task| task.key?(:ip_address) }

      sleep(1)
    end
    SUCCESS_RESULT
  end

  # Get the IP address for the task
  # @param task_id [String] the task to get the IP address for
  def get_task_ip_address(task_id)
    result = run_command("docker inspect #{task_id}")
    unless result[:value].success?
      @ui.error('Unable to get information about the service')
      return ERROR_RESULT, ''
    end
    task_data = JSON.parse(result[:output])[0]
    if task_data['Status']['State'] == 'running'
      return SUCCESS_RESULT, task_data['NetworksAttachments'][0]['Addresses'][0].split('/')[0]
    end

    [NO_RESULT, '']
  end
end
