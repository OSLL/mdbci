# frozen_string_literal: true

require_relative 'base_command'
require_relative '../models/configuration'
require_relative '../services/shell_commands'

# The command executes a command on behalf of sudo in a virtual machine.
class SudoCommand < BaseCommand
  include ShellCommands

  def self.synopsis
    'Execute a command on behalf of sudo in a virtual machine.'
  end

  def show_help
    info = <<-HELP
'sudo' executes a command on behalf of sudo in a virtual machine.

mdbci sudo --command "ls ~" T/node0 - execute a command on the T/node0

OPTIONS:
  --command [string]:
Specifies the command.
    HELP
    @ui.info(info)
  end

  # Checks that all required parameters are passed to the command
  # and set them as instance variables.
  #
  # @raise [ArgumentError] if unable to parse arguments.
  def setup_command
    if @args.empty? || @args.first.nil?
      raise ArgumentError, 'You must specify path to the mdbci configuration as a parameter.'
    end

    @specification = @args.first
    @config = Configuration.new(@specification)
    raise ArgumentError, 'Config does not exists' unless Dir.exist?(@config.path)
  end

  def sudo
    command_results = @config.node_names.map do |node_name|
      cmd = "vagrant ssh #{node_name} -c '/usr/bin/sudo #{@env.command}'"
      @ui.info("Running #{cmd} on #{@config.name}/#{node_name}")
      result = ShellCommands.run_command_in_dir(@ui, cmd, @config.path)
      next true if result[:value].success?

      @ui.error("Command '#{cmd}' exit with non-zero code: #{result[:value].exitstatus}")
      false
    end
    return ERROR_RESULT if command_results.include?(false)

    SUCCESS_RESULT
  end

  def execute
    if @env.show_help
      show_help
      return SUCCESS_RESULT
    end
    begin
      setup_command
    rescue ArgumentError => error
      @ui.warning error.message
      return ARGUMENT_ERROR_RESULT
    end
    sudo
  end
end
