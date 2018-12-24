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
  # @param args [Array<String>] list of arguments for the curernt command.
  # @param env [Session] reference to the GOD object of this application.
  # @param logger [Out] the object that should be used to log information.
  # @param options [Hash] additional options that will be passed to executed command
  def initialize(args, env, logger, options = {})
    @args = args
    @env = env.clone
    options.each_pair do |key, value|
      @env.send("#{key}=", value) if @env.class.method_defined?("#{key}=")
    end
    @ui = logger
  end

  # This method is called whenever the command is executed. Any
  # subclasses must implement this method in order to be called.
  #
  # @return [Number] exit code for the command execution.
  def execute
    raise "#{self.class} must implement execute method."
  end

  # Creates new instance of command and executes it
  #
  # @return [Number] exit code of the executed command
  def self.execute(args, env, logger, options)
    command = new(args, env, logger, options)
    command.execute
  end
end
