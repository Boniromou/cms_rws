require 'logger'

module Hood
module Loggable
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    if defined? Rails
      $hood_logger = Rails.logger
      $hood_backtrace_cleaner = Rails.backtrace_cleaner
    else
      $hood_logger = Logger.new(STDOUT)
    end
  end

  module ClassMethods
    def logger
      $hood_logger
    end

    def log_exception(e, msg = nil)
      logger.error(msg) if msg
      logger.error "  Exception\n  [#{e.class}] #{e.message}\n  "
      logger.error(get_clean_backtrace(e.backtrace))
    end

    def get_clean_backtrace(backtrace)
      if $hood_backtrace_cleaner
        $hood_backtrace_cleaner.clean(backtrace).join("\n  ")
      else
        backtrace.join("\n  ")
      end
    end

  end

  module InstanceMethods
    def log_exception(e, msg = nil)
        self.class.log_exception(e, msg)
    end

    def logger
      self.class.logger
    end
  end

end
end

