class Player < ActiveRecord::Base
  include ActionView::Helpers
  include FundHelper
  attr_accessible :balance, :card_id, :currency_id,:member_id, :player_name, :status
  validates_uniqueness_of :member_id, :card_id

  def balance_str
    to_display_amount_str(balance)
  end

  def self.create_by_params(params)
    verify_player_params(params)

    card_id = params[:card_id]
    member_id = params[:member_id]
    player_name = params[:player_name].downcase

    player = new
    player.card_id = card_id
    player.member_id = member_id
    player.player_name = player_name
    player.balance = 0
    player.currency_id = 1
    player.status = "active"
    begin
      player.save!
    rescue ActiveRecord::RecordInvalid => ex
      duplicated_filed = ex.record.errors.keys.first.to_s
      raise CreatePlayer::DuplicatedFieldError, duplicated_filed
    end
  end

  def self.update_by_params(params)
    verify_player_params(params)

    card_id = params[:card_id]
    member_id = params[:member_id]
    player_name = params[:player_name].downcase

    player = find_by_member_id(member_id)
    player.card_id = card_id
    player.player_name = player_name
    begin
      player.save!
    rescue
      raise "duplicate"
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

  protected

  class << self
    def str_is_i?(str)
      !!(str =~ /^[0-9]+$/)
    end

    def verify_player_params(params)
      card_id = params[:card_id]
      member_id = params[:member_id]
      player_name = params[:player_name]

      raise CreatePlayer::ParamsError, "card_id_length_error" if card_id.nil? || card_id.blank?
      raise CreatePlayer::ParamsError, "member_id_length_error" if member_id.nil? || member_id.blank?
      raise CreatePlayer::ParamsError, "name_blank_error" if player_name.nil? || player_name.blank?

      raise CreatePlayer::ParamsError, "card_id_only_number_allowed_error" if !str_is_i?(card_id)
      raise CreatePlayer::ParamsError, "member_id_only_number_allowed_error" if !str_is_i?(member_id)
    end
  end
end
