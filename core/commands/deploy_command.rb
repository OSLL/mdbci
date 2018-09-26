# frozen_string_literal: true

require 'fileutils'
require_relative 'base_command'

# Command provides a documentation to the user on how to use the mdbci tool.
class DeployCommand < BaseCommand
  def self.synopsis
    'Deploy examples from AppImage to the current working directory.'
  end

  def execute
    begin
      @ui.info("Copying files to #{File.join(@env.working_dir, 'confs')} and #{File.join(@env.working_dir, 'scripts')}")
      FileUtils.cp_r(File.join(@env.mdbci_dir, 'confs'), @env.working_dir)
      FileUtils.cp_r(File.join(@env.mdbci_dir, 'scripts'), @env.working_dir)
    rescue StandardError => error
      @ui.error("Unable to copy data. Error information: #{error.message}")
      return ERROR_RESULT
    end
    SUCCESS_RESULT
  end
end
