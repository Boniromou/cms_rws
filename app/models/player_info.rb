class PlayerInfo
  
  class << self
    def retrieve_info(card_id, terminal_id, pin)
      @wallet_requester = Requester::Standard.new(PROPERTY_ID, 'test_key', WALLET_URL + WALLET_PATH) unless @wallet_requester
      return {:status => 400, :error_code => 'InvalidTerminal', :error_msg => 'Terminal is invalid'} unless validate_terminal(terminal_id)
      player = Player.find_by_card_id(card_id)
      return {:status => 400, :error_code => 'InvalidCardId', :error_msg => 'Card id is not exist'} unless player
      return {:status => 400, :error_code => 'PlayerLocked', :error_msg => 'Player is locked'} if player.account_locked?
      login_name = player.member_id
      return {:status => 400, :error_code => 'InvalidPin', :error_msg => 'Pin is wron with card id'} unless validate_pin(login_name, pin)
      currency = player.currency.name
      balance = @wallet_requester.get_player_balance(player.member_id)
      session_token = Token.generate(player.id).session_token

      {:login_name => login_name, :currency => currency, :balance => balance, :session_token => session_token}
    end

    def validate_terminal(terminal_id)
      #TODO validate terminal
      true
    end

    def validate_pin(login_name, pin)
      #TODO validate pin
      true
    end
  end
end
