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
      response = Token.validate(@inbound[:login_name], @inbound[:session_token])
      unless response.is_a?(Hash)
        return {}
      else 
        return response
      end
    end
    
    def process_retrieve_player_info_event
      card_id = @inbound[:card_id]
      terminal_id = @inbound[:terminal_id]
      pin = @inbound[:pin]
      property_id = @inbound[:property_id]

      player = Player.find_by_card_id(card_id)
      return {:status => 400, :error_code => 'InvalidCardId', :error_msg => 'Card id is not exist'} unless player
      login_name = player.member_id
      currency = player.currency.name
      balance = @wallet_requester.get_player_balance(player.member_id)
      #TODO gen a real token
      session_token = 'abm39492i9jd9wjn'

      {:login_name => login_name, :currency => currency, :balance => balance, :session_token => session_token}
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

