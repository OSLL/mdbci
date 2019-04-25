# frozen_string_literal: true

require 'erb'
require_relative 'destroy_command'
require_relative 'generate_command'
require_relative 'snapshot_command'
require_relative 'up_command'
require_relative 'generate_product_repositories_command'
require_relative 'configure_command'
require_relative 'deploy_command'
require_relative 'setup_dependencies_command'

# Command provides a documentation to the user on how to use the mdbci tool.
class HelpCommand < BaseCommand
  def self.synopsis
    'Show information about MDBCI tool and it commands.'
  end

  HELP_TEMPLATE_FILE = File.expand_path('../../../docs/help.erb', __FILE__)

  COMMANDS = {
    'check_relevance' => 'Check for relevance of network_config file.',
    'clone' => 'Clone existing configuration into a new one.',
    'configure' => ConfigureCommand.synopsis,
    'deploy-examples' => DeployCommand.synopsis,
    'destroy' => DestroyCommand.synopsis,
    'generate' => GenerateCommand.synopsis,
    'generate-product-repositories' => GenerateProductRepositoriesCommand.synopsis,
    'help' => HelpCommand.synopsis,
    'install_product' => 'Install a product onto the configuration node.',
    'public_keys' => 'Copy ssh keys to configured nodes.',
    'setup' => 'Download boxes to the vagrant.',
    'setup-dependencies' => SetupDependenciesCommand.synopsis,
    'setup_repo' => 'Install product repository and update it.',
    'show' => 'Get information about mdbci and configurations.',
    'snapshot' => SnapshotCommand.synopsis,
    'ssh' => 'Execute command on the configuration node.',
    'sudo' => 'Execute command using sudo on the node.',
    'up' => UpCommand.synopsis,
    'validate_template' => 'Check that template has valid syntax.'
  }.freeze

  # Show overview about all the commands that are available
  def show_overview
    name_width = COMMANDS.keys.map(&:size).max
    command_descriptions = COMMANDS.map do |name, info|
      format("%-#{name_width}<name>s %<info>s", { name: name, info: info })
    end.join("\n")
    File.open(HELP_TEMPLATE_FILE) do |file|
      template = ERB.new(file.read)
      @ui.out(template.result(binding))
    end
  end

  def execute
    show_overview
    SUCCESS_RESULT
  end
end
