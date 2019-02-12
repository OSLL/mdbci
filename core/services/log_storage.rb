# frozen_string_literal: true

require_relative '../out'

# Class provides storage of logs
class LogStorage < Out
  # @param configuration [Session] configuration object that can silence the output
  def initialize(configuration)
    super(configuration)
    @logs = []
  end

  def out(string)
    return if string.nil?

    @logs.push(string)
  end

  def print_to_stdout
    @logs.each { |log_line| @stream.puts(log_line) }
  end

  protected

  def print_line(level, string)
    return if string.nil?

    timestamp = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
    @logs.push("#{timestamp} #{level}: #{string}")
  end
end
