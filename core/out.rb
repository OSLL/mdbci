require_relative  '../core/session'

class Out

  #TODO: define Log Level related behavior

  attr_reader :INFO
  attr_reader :WARNING
  attr_reader :ERROR

  def initialize
    @INFO = ' INFO:  '
    @WARNING = ' WARN:  '
    @ERROR = 'ERROR:  '
  end

  def out(string)
    puts string
  end

  def info(string)
    if !$session.isSilent && !string.nil?
      puts @INFO + string
    end
  end

  def warning(string)
    if !$session.isSilent && !string.nil?
      puts @WARNING + string
    end
  end

  def error(string)
    if !$session.isSilent && !string.nil?
      puts @ERROR + string
    end
  end

end