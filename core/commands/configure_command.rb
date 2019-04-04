# frozen_string_literal: true

require_relative 'base_command'
require_relative '../services/aws_service'

# Class that creates configuration file for MDBCI. Currently it consists of AWS support.
class ConfigureCommand < BaseCommand
  def self.synopsis
    'Creates configuration file for MDBCI'
  end

  def initialize(arg, env, logger)
    super(arg, env, logger)
    @configuration = @env.tool_config
  end

  def show_help
    info = <<-HELP
'configure' command creates configuration for MDBCI to use AWS and RHEL subscription.

You can configure AWS and RHEL credentials:
  mdbci configure

Or you can configure only AWS or only RHEL credentials (for example, AWS):
  mdbci configure --product aws
    HELP
    @ui.info(info)
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def execute
    if @env.show_help
      show_help
      return SUCCESS_RESULT
    end
    configure_results = []

    configure_results << configure_aws if @env.nodeProduct.casecmp('aws').zero? || @env.nodeProduct.nil?
    configure_results << configure_rhel if @env.nodeProduct.casecmp('rhel').zero? || @env.nodeProduct.nil?

    return ERROR_RESULT if configure_results.include?(ERROR_RESULT)

    @configuration.save
    SUCCESS_RESULT
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  private

  def configure_aws
    aws_credentials = input_aws_credentials
    return ERROR_RESULT if aws_credentials.nil?

    aws_security_group = input_or_create_security_group(aws_credentials)
    aws_credentials['security_group'] = aws_security_group
    @configuration['aws'] = aws_credentials
    SUCCESS_RESULT
  end

  def configure_rhel
    rhel_credentials = input_rhel_subscription_credentials
    return ERROR_RESULT if rhel_credentials.nil?

    @configuration['rhel'] = rhel_credentials
    SUCCESS_RESULT
  end

  def input_rhel_subscription_credentials
    {
      'username' => read_topic('Please input username for Red Hat Subscription-Manager'),
      'password' => read_topic('Please input password for Red Hat Subscription-Manager')
    }
  end

  def input_or_create_security_group(credentials)
    if read_topic('Create new AWS security group?', 'y').casecmp('y').zero?
      aws_service = AwsService.new(credentials, @ui)
      security_group = aws_service.create_security_group
      return ERROR_RESULT if security_group.nil?

      @ui.info("Created new security group: #{security_group}")
      security_group
    else
      read_topic('Please input the name of AWS security group', '')
    end
  end

  def input_aws_credentials
    key_id = ''
    secret_key = ''
    region = 'eu-west-1'
    loop do
      key_id = read_topic('Please input AWS key id', key_id)
      secret_key = read_topic('Please input AWS secret key', secret_key)
      region = read_topic('Please input AWS region', region)
      check_complete = AwsService.check_credentials(@ui, key_id, secret_key, region)
      break if check_complete

      @ui.error('You have provided inappropriate information.')
      return nil unless read_topic('Try again?', 'y').casecmp('y').zero?
    end
    { 'access_key_id' => key_id, 'secret_access_key' => secret_key, 'region' => region }
  end

  # Ask user to input non-empty string as value
  def read_topic(topic, default_value = '')
    loop do
      $stdout.print("#{topic} [#{default_value}]: ")
      user_input = $stdin.gets.strip
      user_input = default_value if user_input.empty?
      break user_input unless user_input.empty?

      $stdout.puts("Please provide the #{topic}.")
    end
  end
end
