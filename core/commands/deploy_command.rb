# frozen_string_literal: true

require 'erb'
require_relative 'base_command'
require_relative '../services/shell_commands'

# Command provides a documentation to the user on how to use the mdbci tool.
class DeployCommand < BaseCommand
  def self.synopsis
    'Deploy examples from AppImage.'
  end

  DEPLOY_PATH = File.expand_path('../../../', __FILE__)

  def execute
    cp_cmd = 'cp -r ' + DEPLOY_PATH + '/confs .'
    result = ShellCommands.run_command($out, cp_cmd)
    cp_cmd = 'cp -r ' + DEPLOY_PATH + '/scripts .'
    result = ShellCommands.run_command($out, cp_cmd)

    SUCCESS_RESULT
  end
end
