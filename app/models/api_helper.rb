class ApiHelper
  
  class << self

    def get_currency(login_name, property_id)
      player = Player.find_by_member_id_and_property_id(login_name, property_id)
      raise Request::InvalidLoginName.new unless player
      currency = player.currency.name
      {:currency => currency}
    end

    def lock_player(login_name, property_id)
      player = Player.find_by_member_id_and_property_id(login_name, property_id)
      raise Request::InvalidLoginName.new unless player
      player.lock_account!
      casino = Property.find(property_id).casino
      ChangeHistory.create(User.new(:name => 'system', :casino_id => casino.id), player, 'lock')
      {}
    end
  end
end
