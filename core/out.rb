require_relative  '../core/session'

class Out

  #TODO: define Log Level related behavior

  def out(string)
    puts string
  end

  def info(string)
    if !$session.isSilent && !string.nil?
      puts ' INFO:  '+string
    end
  end

  def warning(string)
    if !$session.isSilent && !string.nil?
      puts ' WARN:  '+string
    end
  end

  def error(string)
    if !$session.isSilent && !string.nil?
      puts 'ERROR:  '+string
    end
  end

end