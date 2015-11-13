class PlayerInfo
  
  class << self
    def patron_requester
      Requester::Patron.new(PROPERTY_ID, 'test_key', PATRON_URL)
    end

    def retrieve_info(card_id, machine_token, pin, property_id)
      begin
        @wallet_requester = Requester::Standard.new(PROPERTY_ID, 'test_key', WALLET_URL + WALLET_PATH) unless @wallet_requester
        raise Request::InvalidMachineToken.new  unless validate_machine_token(machine_token, property_id)
        player = Player.find_by_card_id_and_property_id(card_id, property_id)
        raise Request::InvalidCardId.new unless player
        raise Request::PlayerLocked.new if player.account_locked?
        login_name = player.member_id
        raise Request::InvalidPin.new unless validate_pin(login_name, pin)
        currency = player.currency.name
        balance = @wallet_requester.get_player_balance(player.member_id)
        raise Request::RetrieveBalanceFail.new unless balance.class == Float
        session_token = Token.generate(player.id).session_token
        {:login_name => login_name, :currency => currency, :balance => balance, :session_token => session_token}
      end
    end

    def validate_machine_token(machine_token, property_id)
      response = Machine.validate(machine_token, property_id)
      return true if response[:error_code] == 'OK'
      false
    end

    def validate_pin(login_name, pin)
      begin
      # patron_requester.validate_pin(login_name, pin)
        response = patron_requester.validate_pin(login_name, pin)
        if response.class != Hash
          Rails.logger.error "validate pin fail"
          return true
        end
        return true if response.class == Hash
      rescue Remote::PinError
      rescue Remote::PlayerNotFound
        return false
      end
    end

    def get_currency(login_name, property_id)
      player = Player.find_by_member_id_and_property_id(login_name, property_id)
      raise Request::InvalidLoginName.new unless player
      currency = player.currency.name
      {:currency => currency}
    end
    
    def update!(id_type, id_value)
      player_info = patron_requester.get_player_info(id_type, id_value)
      # player_info = {:card_id => '02338431000000041732', :member_id => '8888', :blacklist => false, :pin_status => 'blank'}
      if player_info.class != Hash
        Rails.logger.error "update player info fail"
        return
      end
      if player_info[:pin_status] == 'blank'
        player = Player.create_inactivate(player_info)
        raise PlayerProfile::PlayerNotActivated.new(player)
      end
      Player.update_info(player_info)
    end

    def update(id_type, id_value)
      begin
        update!(id_type, id_value)
      rescue PlayerProfile::PlayerNotActivated => e
        return 'PlayerNotActivated'
      end
    end
  end
end
