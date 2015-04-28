class Player < ActiveRecord::Base
  attr_accessible :balance, :card_id, :currency_id,:member_id, :player_name, :status

  def self.create_by_params(params)
    card_id = params[:card_id]
    member_id = params[:member_id]
    player_name = params[:player_name]

    raise ArgumentError , "create_player_error.card_id_blank_error" if card_id.blank?
    raise ArgumentError , "create_player_error.member_id_blank_error" if member_id.blank?
    raise ArgumentError , "create_player_error.name_blank_error" if player_name.blank?

    result = false

    player = new
    player.card_id = card_id
    player.member_id = member_id
    player.player_name = player_name
    player.balance = 0
    player.currency_id = 1
    player.status = "active"
    begin
      result = player.save
      return result
    rescue
      raise Exception, "create_player.exist"
    end
  end

  def self.fund_in(member_id, amount)
    player = find_by_member_id(member_id)
    player.balance += amount
    player.save
  end
  
  def self.fund_out(member_id, amount)
    player = find_by_member_id(member_id)
    player.balance -= amount
    player.save
  end

  def self.find_by_type_id(id_type, id_number)
    if id_type == "member_id"
      find_by_member_id(id_number)
    else
      find_by_card_id(id_number)
    end
  end
end
