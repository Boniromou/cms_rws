class Player < ActiveRecord::Base
  attr_accessible :balance, :card_id, :currency_id,:member_id, :player_name, :status

  def self.create_by_param(member_id,player_name)
    raise ArgumentError , "create_player_error.id_blank_error" if member_id.blank?
    raise ArgumentError , "create_player_error.name_blank_error" if player_name.blank?
    player = new
    player.member_id = member_id
    player.player_name = player_name
    player.balance = 0
    player.currency_id = 1
    player.status = "unlock"
    result = false
    begin
      result = player.save
      [result,player]
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
end
