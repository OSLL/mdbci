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
'configure' command creates configuration for MDBCI to use with AWS.
    HELP
    @ui.info(info)
  end

  def execute
    if @env.show_help
      show_help
      return SUCCESS_RESULT
    end
    credentials = input_aws_credentials
    return ERROR_RESULT if credentials.nil?
    security_group = input_or_create_security_group
    credentials['security_group'] = security_group
    @configuration['aws'] = credentials
    @configuration.save
    SUCCESS_RESULT
  end

  private

  def input_or_create_security_group
    if read_topic('Create new AWS security group?', 'y').downcase == 'y'
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
      break nil unless read_topic('Try again?', 'y').downcase == 'y'
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
