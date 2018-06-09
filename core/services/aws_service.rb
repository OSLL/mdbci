require 'aws-sdk-ec2'
require 'socket'

# This class allows to execute commands in accordance to the AWS EC2
class AwsService
  def initialize(aws_config)
    @client = Aws::EC2::Client.new(
      access_key_id: aws_config['access_key_id'],
      secret_acess_key: aws_config['secret_access_key'],
      region: aws_config['region']
    )
  end

  # Generate key pair for the specified configuration path
  # @param [String] configuration_path is path to configuration for which key pair is generated
  # @raise [RuntimeError] if unable to generate key pair
  # @return [Aws::EC2::Types::KeyPair] generated key pair information
  def generate_key_pair(configuration_path)
    hostname = Socket.gethostname
    keypair_name = File.basename(configuration_path)
    key_name = "#{hostname}_#{keypair_name}_#{Time.now.to_i}"
    @client.create_key_pair(key_name: key_name)
  end

  # Delete key pair by the name
  # @param [String] name of the key pair to delete
  def delete_key_pair(name)
    @client.delete_key_pair(key_name: name)
  end
end
