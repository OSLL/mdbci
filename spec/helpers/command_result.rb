# frozen_string_literal: true

require 'open3'

# Class captures the result of running the command with Open3.capture2e and
# provides convenient access to the values.
class CommandResult
  attr_reader :command, :messages, :result

  # Alternative form of constructing the result from the command
  #
  # @param command [String] command to execture
  # @returm [CommandResult] object representing the result.
  def self.for_command(command)
    CommandResult.new(command, *Open3.capture2e(command))
  end

  # Creates new instance of the object
  #
  # @param command [String] command that was executed.
  # @param stdout_all [String] list of stdout and stderr messages separated by '\n'
  # @param result [Process::Status] status of running the code
  def initialize(command, out_all, result)
    @command = command
    @messages = out_all
    @result = result
  end

  # Check for result of running the project
  def success?
    @result.success?
  end

  def to_s
    "Command: #{@command}\nExit status: #{@result}\nOutput:\n#{@messages}"
  end
end
