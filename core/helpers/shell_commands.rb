# frozen_string_literal: true

# This is the mixin that executes commands on the shell, logs it.
# Mixin depends on @ui instance variable that points to the logger.
module ShellCommands
  # rubocop:disable Metrics/MethodLength
  # Execute the command, log stdout and stderr
  #
  # @param command [String] command to run
  # @param options [Hash] options that are passed to popen3 command.
  # @return [Process::Status] of the run command
  def run_command_and_log(command, options = {})
    @ui.info "Invoking command: #{command}"
    Open3.popen3(command, options) do |stdin, stdout, stderr, wthr|
      stdin.close
      output = []
      stdout.each_line do |line|
        @ui.info line
        output.push line
      end
      errors = []
      stderr.each_line do |line|
        @ui.error line
        errors.push line
      end
      {
        value: wthr.value,
        output: output.join("\n"),
        errors: errors.join("\n")
      }
    end
  end
  # rubocop:enable Metrics/MethodLength

  # Execute the command, log stdout and stderr.
  #
  # @param command [String] command to run
  # @param directory [String] path to the directory to run the command
  # return [Process::Status] of the run command
  def run_command_in_dir(command, directory)
    run_command_and_log(command, { chdir: directory })
  end

  # Execute the command, log stdout and stderr. If command was not
  # successfull, then print information to error stream.
  #
  # @param command [String] command to run
  # @param message [String] message to display in case of failure
  # @param options [Hash] options that are passed to the popen3 method
  def check_command(command, message, options = {})
    result = run_command_and_log(command, options)
    @ui.error message unless result[:value].success?
    result
  end

  # Execute the command in the specified directory, log stdout and stderr.
  # If command was not successfull, then print it onto error stream.
  #
  # @param command [String] command to run
  # @param dir [String] directory to run command in
  # @param message [String] message to display in case of failure
  def check_command_in_dir(command, directory, message)
    check_command(command, message, { chdir: directory })
  end
end
