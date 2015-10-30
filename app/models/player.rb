class Player < ActiveRecord::Base
  belongs_to :currency
  has_many :tokens
  has_many :players_lock_types
  include ActionView::Helpers
  include FundHelper
  attr_accessible :card_id, :currency_id,:member_id, :first_name, :status, :last_name, :id, :property_id
  validates_uniqueness_of :member_id, :card_id

  STATUS_LOCKED = 'locked'
  STATUS_NORMAL = 'active'

  LOCK_TYPE_CAGE_LOCK = 'cage_lock'

  def full_name
    first_name = self.first_name || ""
    last_name = self.last_name || ""
    first_name + " " + last_name
  end

  def balance_str
    to_display_amount_str(balance)
  end

  def account_locked?
    return status == STATUS_LOCKED
  end

  def cage_locked?
    has_lock_type?(LOCK_TYPE_CAGE_LOCK)
  end

  def has_lock_type?(lock_type)
    self.lock_types.include?(lock_type)
  end

  def lock_account!(lock_type_name = LOCK_TYPE_CAGE_LOCK)
    Player.transaction do
      PlayersLockType.add_lock_to_player(self.id, lock_type_name)
      update_lock_status
      discard_tokens
    end
  end

  def unlock_account!(lock_type_name = LOCK_TYPE_CAGE_LOCK)
    Player.transaction do
      PlayersLockType.remove_lock_to_player(self.id, lock_type_name)
      update_lock_status
    end
  end

  def discard_tokens
    if self.tokens != []
      self.tokens.each do |token| 
        token.discard if token.alive?
      end
    end
  end

  def update_lock_status
    if self.status == STATUS_NORMAL && self.lock_types.length > 0
      self.status = STATUS_LOCKED
      self.save
    elsif self.status == STATUS_LOCKED && self.lock_types.length == 0
      self.status = STATUS_NORMAL
      self.save
    end
  end

  def lock_types
    result = []
    self.players_lock_types.each do |players_lock_type|
      result << players_lock_type.lock_type.name if players_lock_type.status == 'active'
    end
    result
  end

  class << self
    def create_by_params(params)
      verify_player_params(params)

      card_id = params[:card_id]
      member_id = params[:member_id]
      first_name = params[:first_name].downcase
      last_name = params[:last_name].downcase

      player = new
      player.card_id = card_id
      player.member_id = member_id
      player.first_name = first_name
      player.last_name = last_name
      player.currency_id = 1
      player.status = STATUS_NORMAL
      begin
        player.save!
      rescue ActiveRecord::RecordInvalid => ex
        duplicated_filed = ex.record.errors.keys.first.to_s
        raise CreatePlayer::DuplicatedFieldError, duplicated_filed
      end
      player
    end

    def update_by_params(params)
      verify_player_params(params)

      card_id = params[:card_id]
      member_id = params[:member_id]
      first_name = params[:first_name].downcase
      last_name = params[:last_name].downcase

      player = find_by_member_id(member_id)
      player.card_id = card_id
      player.first_name = first_name
      player.last_name = last_name
      begin
        player.save!
      rescue
        raise "duplicate"
      end
    end

    def find_by_type_id(id_type, id_number)
      if id_type == "member_id"
        find_by_member_id(id_number)
      else
        find_by_card_id(id_number)
      end
    end

    def create_inactivate(player_info)
      player = Player.new(:member_id => player_info[:member_id], :card_id => player_info[:card_id], :status => 'not_activate')
    end

    def update_info(player_info)
      player = Player.find_by_member_id(player_info[:member_id])
      return unless player
      if player_info[:card_id] != player.card_id
        player.card_id = player_info[:card_id]
        player.save
        player.discard_tokens
      end
      player.lock_account!('blacklist') if player_info[:blacklist]
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
      first_name = params[:first_name]
      last_name = params[:last_name]

      raise CreatePlayer::ParamsError, "card_id_length_error" if card_id.nil? || card_id.blank?
      raise CreatePlayer::ParamsError, "member_id_length_error" if member_id.nil? || member_id.blank?
      raise CreatePlayer::ParamsError, "first_name_blank_error" if first_name.nil? || first_name.blank?
      raise CreatePlayer::ParamsError, "last_name_blank_error" if last_name.nil? || last_name.blank?

      raise CreatePlayer::ParamsError, "card_id_only_number_allowed_error" if !str_is_i?(card_id)
      raise CreatePlayer::ParamsError, "member_id_only_number_allowed_error" if !str_is_i?(member_id)
    end
  end
end
