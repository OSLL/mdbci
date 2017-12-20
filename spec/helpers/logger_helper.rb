# frozen_string_literal: true

require 'logger'

# Module provides a logger method that can be used to obtain
# an instance of logger that will be configured based on
# the environment variable.
# Creates the @logger instance variable.
module LoggerHelper
  # Get access to the logger. Configure it if necessary.
  def logger
    configure_logger if @logger.nil?
    @logger
  end

  private

  # Method setups the logger based on the information
  # from the environment variable 'log'
  def configure_logger
    if ENV.include?('log')
      @logger = Logger.new(STDOUT)
      @logger.sev_threshold = case ENV['log'].downcase
                              when 'debug'
                                Logger::DEBUG
                              when 'info'
                                Logger::INFO
                              when 'warn'
                                Logger::WARN
                              else
                                Logger::INFO
                              end
    else
      @logger = Logger.new('/dev/null')
    end
  end
end
