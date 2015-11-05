class PlayerInfo
  
  class << self
    def patron_requester
      Requester::Patron.new(PROPERTY_ID, 'test_key', PATRON_URL + PATRON_PATH)
    end

    def retrieve_info(card_id, machine_token, pin, property_id)
      @wallet_requester = Requester::Standard.new(PROPERTY_ID, 'test_key', WALLET_URL + WALLET_PATH) unless @wallet_requester
      return {:status => 400, :error_code => 'InvalidMachineToken', :error_msg => 'Machine token is invalid'} unless validate_machine_token(machine_token, property_id)
      player = Player.find_by_card_id_and_property_id(card_id, property_id)
      return {:status => 400, :error_code => 'InvalidCardId', :error_msg => 'Card id is not exist'} unless player
      return {:status => 400, :error_code => 'PlayerLocked', :error_msg => 'Player is locked'} if player.account_locked?
      login_name = player.member_id
      return {:status => 400, :error_code => 'InvalidPin', :error_msg => 'Pin is wron with card id'} unless validate_pin(login_name, pin)
      currency = player.currency.name
      balance = @wallet_requester.get_player_balance(player.member_id)
      return {:status => 500, :error_code => 'RetrieveBalanceFail', :error_msg => 'Retrieve balance from wallet fail'} unless balance.class == Float
      session_token = Token.generate(player.id).session_token

      {:login_name => login_name, :currency => currency, :balance => balance, :session_token => session_token}
    end

    def validate_machine_token(machine_token, property_id)
      # response = Machine.validate(machine_token, property_id)
      # return false if response[:error_code] != 'OK' 
      true
    end

    def validate_pin(login_name, pin)
      #TODO validate pin
      true
    end

    def get_currency(login_name, property_id)
      player = Player.find_by_member_id_and_property_id(login_name, property_id)
      raise Request::InvalidLoginName.new unless player
      currency = player.currency.name
      {:currency => currency}
    end
    
    def update!(id_type, id_value)
      player_info = patron_requester.get_player_info(id_type, id_value)
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
