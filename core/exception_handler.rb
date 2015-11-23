require_relative 'out'

class ExceptionHandler
  def handle(info=nil)
    begin
      return yield
    rescue Exception => details
      if !info.to_s.empty?
        $out.error info
      end
      $out.error details.message
      details.backtrace.reverse.each do |detail|
        $out.error detail
      end
      exit -1
    end
  end
end
