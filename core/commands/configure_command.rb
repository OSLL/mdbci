require_relative 'base_command'

class ConfigureCommand < BaseCommand
  def self.synopsis
    'Creates configuration file for MDBCI'
  end

  def initialize(arg, env, ui)
    super(arg, env, ui)
  end

  def execute

  end
end
