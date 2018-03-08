# frozen_string_literal: true

# This is the mixin that executes commands on the shell, logs it.
# Mixin depends on @ui instance variable that points to the logger.
module ShellCommands
  # rubocop:disable Metrics/MethodLength
  # Execute the command, log stdout and stderr
  #
  # @param command [String] command to run
  # @param options [Hash] options that are passed to popen3 command.
  # @param env [Hash] environment parameters that are passed to popen3 command.
  # @return [Process::Status] of the run command
  def run_command_and_log(command, options = {}, env = {})
    @ui.info "Invoking command: #{command}"
    Open3.popen3(env, command, options) do |stdin, stdout, stderr, wthr|
      stdin.close
      output = ''
      errors = ''
      loop do
        read, _, _ = IO.select([stdout, stderr])
        read.each do |stream|
          line = stream.gets.to_s.strip
          next if line.empty?
          if stream == stdout
            @ui.info(line)
            output += line
          elsif stream == stderr
            @ui.error(line)
            errors += line
          else
            @ui.error(line)
            errors += line
          end
        end
        break if stdout.eof? && stderr.eof?
      end
      {
        value: wthr.value,
        output: output,
        errors: errors
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
