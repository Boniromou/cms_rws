require 'singleton'
  class RequestHandler
    include Singleton

    def update(inbound)
      @inbound = inbound
      @wallet_requester = Requester::Standard.new(PROPERTY_ID, 'test_key', WALLET_URL + WALLET_PATH) unless @wallet_requester
      begin
        event_name = inbound[:_event_name].to_sym
        @outbound = self.__send__("process_#{event_name}_event") || {}
      rescue Exception => e
        puts e.backtrace
        puts e.message
        {:status => 500, :error_code => 'internal error', :error_msg => 'e.message'}
      end
      if @outbound[:error_code].nil?
        @outbound.merge!({:status=>200, :error_code=>'OK', :error_msg=>'Request is carried out successfully.'})
      end
      @outbound
    end

    def process_validate_token_event
      # response = Token.validate(@inbound[:login_name], @inbound[:session_token])
      # unless response.is_a?(Hash)
      #   return {}
      # else 
      #   return response
      # end
      {}
    end

    def process_retrieve_player_info_event
      Player.retrieve_info(@inbound[:card_id], @inbound[:terminal_id], @inbound[:pin], @inbound[:property_id])
    end

    def process_keep_alive_event
      response = Token.validate(@inbound[:login_name], @inbound[:session_token])
      unless response.is_a?(Hash)
        response.keep_alive
        return {}
      else
        return response
      end
    end

    def process_discard_token_event
      response = Token.validate(@inbound[:login_name], @inbound[:session_token])
      unless response.is_a?(Hash)
        response.discard
        return {}
      else
        return response
      end
    end
  end

