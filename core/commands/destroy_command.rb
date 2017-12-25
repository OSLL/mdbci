# frozen_string_literal: true

require_relative 'base_command'

# Command allows to destroy the whole configuration or a specific node.
class DestroyCommand < BaseCommand
  def self.synopsis
    'Destroy configuration with all artefacts or a node'
  end

  def initialize(args, env, ui)
    super(args, env, ui)

  end

  def execute
    0
  end
end
