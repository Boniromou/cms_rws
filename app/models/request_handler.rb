require 'singleton'
  class RequestHandler
    include Singleton

    def update(inbound)
      @inbound = inbound
      begin
        event_name = inbound[:_event_name].to_sym
        @outbound = self.__send__("process_#{event_name}_event") || {}
      rescue HoodError => e
        log_exception(e)
        @outbound = e.to_hash
      end
      if @outbound[:error_code].nil?
        @outbound.merge!({:status=>200,:error_code=>'OK',:error_msg=>'Request is carried out successfully.'})
      end
      @outbound
    end

    def process_validate_token_event
      {:mamber_id=>3211321}
    end

  end

