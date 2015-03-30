module LaxSupport

  # RWSError is a generic RWS exception class which adds HTTP status code to
  # compile with HTTP standard.
  class RWSError < StandardError
    attr_reader :status_code # http status code

    # Construct a new RWSError object, 
    # optionally passing in a http status code and message
    # If no http status code is specified, 500 (Internal Error) will be used.
    # For HTTP status code definition, please refer to:
    #     http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
    def initialize(status_code=500, error_msg=nil)
      @status_code = status_code
      super(error_msg)
    end

    # Return the exception name as default error code
    def error_code
      self.class.name.split('::').last
    end

    # Return a hash representation for RWS Error
    #   { :status     => <http status code>,
    #     :error_code => <class name for RWS Error>,
    #     :message    => <exception message or name>
    #   }
    def to_hash
      { :status => @status_code , 
        :error_code => self.class.name.split('::').last, 
        :message => message 
      }
    end    
  end

  # RWSErrorHandler is a generic exception handler for Laxino RWS in Rails
  # To make use of it, you can simply include this module to your Rails controller. 
  # 
  #     class ApplicationController < ActionController::Base
  #       include LaxSupport::RWSErrorHandler
  # 
  #       def create
  #         @result = { :status => 200, :text => 'OK' }
  #         ... ...
  #         # Your controlling logic here
  #         # Modify @result as needed
  #         ... ...
  #         respond_with_result(@result) 
  #       end
  #     end
  # 
  # Then, it hooks up the exception handler in the module into your Rails application
  # by using rescue_from which is equivalent to the following:
  #
  #     rescue_from Exception, :with => :handle_exceptions
  # 
  module RWSErrorHandler
    def self.included(base) #:nodoc:
      base.rescue_from Exception, :with => :handle_exceptions
    end

    protected

    # Generic exception handler for Laxino RWS in Rails
    # This handler first uniforms the result for RWS errors
    # and other type of exceptions as the following:
    #
    #   result = 
    #     { :status     => <http status code>,
    #       :error_code => <class name for RWS Error>,
    #       :message    => <exception message or name>
    #     }
    #
    # Then, it logs the exception with formatted backtrace.
    # Finally, it renders result back to RWS client by using
    # #respond_with_result(result), a generic RWS response handler.
    def handle_exceptions(exception, status_code=500)
      if exception.kind_of?(LaxSupport::RWSError)
        result = { :status     => exception.status_code,
                    :error_code => exception.error_code,
                    :text       => exception.message
                  }
      else
        result = { :status     => status_code,
                    :error_code => exception.class.name,
                    :text       => exception.message
                  }
      end

      logger.fatal "\n\n[#{exception.class}] #{exception.message}:\n    " +
                   clean_backtrace(exception).join("\n    ") +
                   "\n\n"

      respond_with_result(result)
    end

    # Generic RWS response handler for Rails
    # It accepts a hash as the result in the following format:
    #
    #   result =
    #     { :status     => <http status code>,
    #       :error_code => <class name for RWS Error>,
    #       :message    => <exception message or name>
    #     }
    # 
    # It supports rendering responses in either html or amf format.
    def respond_with_result(result)
      respond_to do |format|
        format.html { render :status => result[:status], :text => result.to_yaml }
        format.amf  { render :amf => result }
      end
    end
  end

end
