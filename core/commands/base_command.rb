# frozen_string_literal: true

# The basis for all the command that can be executed.
# It partially mimics the Command interface from Vagrant.
# @see https://github.com/hashicorp/vagrant/blob/master/lib/vagrant/plugin/v2/command.rb
class BaseCommand
  SUCCESS_RESULT = 0
  ERROR_RESULT = 1
  ARGUMENT_ERROR_RESULT = 2

  # The method should return brief description of the command.
  # It should be less than 60 characters long. It will be used
  # to generate help message.
  #
  # @return [String] help message
  def self.synopsis
    ''
  end

  # Create the command instance.
  #
  # @param ui [Out] the object that should be used to log information.
  # @param args [Array<String>] list of arguments for the curernt command.
  # @param env [Array<String>] information about the environment
  def initialize(ui, args, env)
    @ui = ui
    @args = args
    @env = env
  end

  # This method is called whenever the command is executed. Any
  # subclasses must implement this method in order to be called.
  #
  # @return [Number] exit code for the command execution.
  def execute
    raise "#{self.class} must implement execute method."
  end
end
