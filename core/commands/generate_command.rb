require_relative 'base_command'

# Command acs as the gatekeeper for two generators: Vagrant-based configurator
# and Docker-based configurator
class GenerateCommand < BaseCommand
  def self.synopsis
    'Generate a configuration based on the template.'
  end

  def execute
    command = VagrantConfigurationGenerator.new(@args, @env, @ui)
    command.execute(@args.shift, @env.override)
  end
end
