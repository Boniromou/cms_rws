class ApiHelper
  
  class << self

    def get_currency(login_name, casino_id)
      player = Player.find_by_member_id_and_casino_id(login_name, casino_id)
      raise Request::InvalidLoginName.new unless player
      currency = player.currency.name
      {:currency => currency}
    end

    def lock_player(login_name, casino_id)
      player = Player.find_by_member_id_and_casino_id(login_name, casino_id)
      raise Request::InvalidLoginName.new unless player
      player.lock_account!
      ChangeHistory.create(User.new(:name => 'system', :casino_id => casino_id), player, 'lock')
      {}
    end
  end
end
