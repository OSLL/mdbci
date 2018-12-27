# frozen_string_literal: true

require 'aws-sdk-ec2'
require 'socket'

# This class allows to execute commands in accordance to the AWS EC2
class AwsService
  def self.check_credentials(logger, key_id, secret_key, region)
    client = Aws::EC2::Client.new(
      access_key_id: key_id,
      secret_access_key: secret_key,
      region: region
    )
    begin
      client.describe_account_attributes(dry_run: true)
    rescue Aws::EC2::Errors::DryRunOperation
      true
    rescue Aws::EC2::Errors::AuthFailure, StandardError => error
      logger.error(error.message)
      false
    else
      true
    end
  end

  def initialize(aws_config, logger)
    @client = Aws::EC2::Client.new(
      access_key_id: aws_config['access_key_id'],
      secret_access_key: aws_config['secret_access_key'],
      region: aws_config['region']
    )
    @logger = logger
  end

  # Generate key pair for the specified configuration path
  # @param [String] configuration_path is path to configuration for which key pair is generated
  # @raise [RuntimeError] if unable to generate key pair
  # @return [Aws::EC2::Types::KeyPair] generated key pair information
  def generate_key_pair(configuration_path)
    hostname = Socket.gethostname
    key_pair_name = File.basename(configuration_path)
    key_name = "#{hostname}_#{key_pair_name}_#{Time.now.to_i}"
    @client.create_key_pair(key_name: key_name)
  end

  # Delete key pair by the name
  # @param [String] name of the key pair to delete
  def delete_key_pair(name)
    @client.delete_key_pair(key_name: name)
  end

  # Get information about instances
  # @return [Hash] instances information
  def describe_instances
    @client.describe_instances.to_h
  end

  # Check whether instance with the specified id running or not.
  # @param [String] instance_id to check
  # @return [Boolean] true if it is running
  def instance_running?(instance_id)
    response = @client.describe_instance_status(instance_ids: [instance_id])
    response.instance_statuses.any? do |status|
      status.instance_id == instance_id &&
        %w[pending running].include?(status.instance_state.name)
    end
  end

  # Terminate instance specified by the unique identifier
  # @param [String] instance_id to terminate
  def terminate_instance(instance_id)
    @client.terminate_instances(instance_ids: [instance_id])
    nil
  end

  GROUP_PERMISSIONS = %w[tcp udp icmp].map do |protocol|
    {
      ip_protocol: protocol,
      from_port: 0,
      to_port: protocol == 'icmp' ? -1 : 65_535,
      ip_ranges: [{ cidr_ip: '0.0.0.0/0' }]
    }
  end.freeze

  # Create and configure security group for the current machine
  # @return [String] new security group name
  def create_security_group
    group_name = "#{Socket.gethostname}_#{Time.now.strftime('%s')}"
    begin
      create_security_group_result = @client.create_security_group(
        group_name: group_name,
        description: "MDBCI #{group_name} auto generated"
      )
    rescue Aws::EC2::Errors::InvalidGroupDuplicate => error
      @logger.error("Error during creation of the security group: #{error}")
      return nil
    end
    @client.authorize_security_group_ingress(
      group_id: create_security_group_result.group_id,
      ip_permissions: GROUP_PERMISSIONS
    )
    group_name
  end
end
