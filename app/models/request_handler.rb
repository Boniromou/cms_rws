require 'singleton'
  class RequestHandler
    include Singleton

    def update(inbound)
      @inbound = inbound
      @iwms_requester = Requester::Standard.new(PROPERTY_ID, 'test_key', IWMS_URL + IWMS_PATH) unless @iwms_requester
      begin
        event_name = inbound[:_event_name].to_sym
        @outbound = self.__send__("process_#{event_name}_event") || {}
      rescue Exception => e
        puts e.backtrace
        puts e.message
        {:status => 500, :error_code => 'internal error', :error_msg => 'e.message'}
      end
      if @outbound[:error_code].nil?
        @outbound.merge!({:status=>200,:error_code=>'OK',:error_msg=>'Request is carried out successfully.'})
      end
      @outbound
    end

    def process_validate_token_event
      #TODO if token validate
      {}
    end

    def process_retrieve_player_info_event
      card_id = @inbound[:card_id]
      terminal_id = @inbound[:terminal_id]
      pin = @inbound[:pin]
      property_id = @inbound[:property_id]

      player = Player.find_by_card_id(card_id)
      login_name = player.member_id
      currency = player.currency.name
      balance = @iwms_requester.get_player_balance(player.member_id)

      {:login_name => login_name, :currency => currency, :balance => balance}
    end

  end

