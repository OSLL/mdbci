# frozen_string_literal: true

# This is the mixin that executes commands on the shell, logs it.
# Mixin depends on @ui instance variable that points to the logger.
module ShellCommands
  # rubocop:disable Metrics/MethodLength
  # Execute the command, log stdout and stderr
  #
  # @param command [String] command to run
  # @param show_idle_notifications [Boolean] show notifications when there is no
  # @param options [Hash] options that are passed to popen3 command.
  # @param env [Hash] environment parameters that are passed to popen3 command.
  # @return [Process::Status] of the run command
  # def run_command_and_log(command, show_idle_notifications = false, options = {}, env = {})
  #   @ui.info "Invoking command: #{command}"
  #   Open3.popen3(env, command, options) do |stdin, stdout, stderr, wthr|
  #     stdin.close
  #     output = ''
  #     errors = ''
  #     until stdout.eof? && stderr.eof?
  #       data = IO.select([stdout, stderr], nil, nil, 1)
  #       read, _, _ = data
  #       p data
  #       if read.empty?
  #         @ui.error("Process had no output for 5 minutes. Status: #{wthr.status}") if show_idle_notifications
  #         @ui.error('I was here!')
  #         next
  #       end
  #       read.each do |stream|
  #         line = stream.gets.to_s.strip
  #         next if line.empty?
  #         if stream == stdout
  #           @ui.info(line)
  #           output += line
  #         else
  #           @ui.error(line)
  #           errors += line
  #         end
  #       end
  #     end
  #     {
  #       value: wthr.value,
  #       output: output,
  #       errors: errors
  #     }
  #   end
  # end
  # rubocop:enable Metrics/MethodLength

  # Execute the command, log stdout and stderr
  #
  # @param command [String] command to run
  # @param show_idle_notifications [Boolean] show notifications when there is no
  # @param options [Hash] options that are passed to popen3 command.
  # @param env [Hash] environment parameters that are passed to popen3 command.
  # @return [Process::Status] of the run command
  # rubocop:disable Metrics/MethodLength
  def run_command_and_log(command, show_idle_notifications = false, options = {}, env = {})
    @ui.info "Invoking command: #{command}"
    Open3.popen3(env, command, options) do |stdin, stdout, stderr, wthr|
      stdin.close
      stdout_text = ''
      stderr_text = ''
      loop do
        wait_streams = []
        wait_streams << read_stream(stdout) do |line|
          @ui.info(line)
          stdout_text += line
        end
        wait_streams << read_stream(stderr) do |line|
          @ui.error(line)
          stderr_text += line
        end
        alive_streams = wait_streams.reject(&:nil?)
        break if alive_streams.empty?
        result = IO.select(alive_streams, nil, nil, 300)
        if result.nil? && show_idle_notifications
          @ui.error("The running command was inactive for 5 minutes.")
          @ui.error("The command is: '#{command}'.")
        end
      end
      {
        value: wthr.value,
        output: stdout_text,
        errors: stderr_text
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
    run_command_and_log(command, false, { chdir: directory })
  end

  # Execute the command, log stdout and stderr. If command was not
  # successfull, then print information to error stream.
  #
  # @param command [String] command to run
  # @param message [String] message to display in case of failure
  # @param options [Hash] options that are passed to the popen3 method
  def check_command(command, message, options = {})
    result = run_command_and_log(command, false, options)
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

  private

  # Method reads the data from the stream in the non-blocking manner.
  # Each read string is yield to the assosiated block.
  #
  # @param stream [IO] input stream to read data from.
  # @return [IO] stream or nil if stream has ended. Returninng nil is crusial
  # as we do not have any other information on when stream has ended.
  def read_stream(stream)
    begin
      buf = ''
      loop do
        buf += stream.read_nonblock(10000)
      end
    rescue IO::WaitReadable
      buf.each_line do |line|
        yield line
      end
      return stream
    rescue EOFError
      return nil
    end
  end
end
