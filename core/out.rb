# frozen_string_literal: true

# Class provides means to produce output to the application
class Out
  # @param configuration [Session] configuration object that can silence the output
  def initialize(configuration)
    @configuration = configuration
    @stream = $stdout
    @stream.sync = true
  end

  def out(string)
    return if string.nil?
    @stream.puts(string)
  end

  def info(string)
    print_line('INFO', string)
  end

  def warning(string)
    print_line('WARNING', string)
  end

  def error(string)
    print_line('ERROR', string)
  end

  private

  def print_line(level, string)
    return if @configuration.isSilent || string.nil?
    @stream.puts("#{level}: #{string}")
  end
end
