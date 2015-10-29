require File.expand_path(File.dirname(__FILE__) + "/base")

class Requester::Standard < Requester::Base
  RETRY_TIMES = 3

  protected
  def retry_call(retry_times, &block)
    begin
      puts "***************retry_times: #{RETRY_TIMES - retry_times}***************"
      return block.call
    rescue Remote::ReturnError => e
      return e.message
    rescue Remote::RaiseError => e
      raise e
    rescue Exception => e
      Rails.logger.error "#{e.message}"
      Rails.logger.error "#{e.backtrace.inspect}"
      if retry_times > 0
        return retry_call(retry_times - 1, &block)
      else
        return e.message
      end
    end
  end
end
