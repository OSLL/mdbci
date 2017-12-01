# frozen_string_literal: true

require_relative 'base_command'

# The command sets up the environment specified in the configuration file.
class UpCommand < BaseCommand
  def self.synopsis
    'Setup environment as specified in the configuration'
  end
end
