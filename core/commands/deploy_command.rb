# frozen_string_literal: true

require 'erb'

# Command provides a documentation to the user on how to use the mdbci tool.
class DeployCommand < BaseCommand
  def self.synopsis
    'Deploy examples from AppImage.'
  end

  DEPLOY_PATH = File.expand_path('../../../confs', __FILE__)

  def execute
    run_command('cp -r #{DEPLOY_PATH} ~/mdbci/')
    SUCCESS_RESULT
  end
end
