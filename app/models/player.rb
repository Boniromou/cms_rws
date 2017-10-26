SELF_ROOT = File.expand_path('.')
require SELF_ROOT + "/lib/promotion_helper"

class Player < ActiveRecord::Base
  belongs_to :currency
  has_many :tokens
  has_many :players_lock_types
  include FundHelper
  attr_accessible :card_id, :currency_id,:member_id, :first_name, :status, :last_name, :id, :licensee_id, :test_mode_player
  validates_uniqueness_of :member_id, scope: [:licensee_id]
  validates_uniqueness_of :card_id, scope: [:licensee_id]

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

  def valid_tokens
    self.tokens.where("expired_at > ?", Time.now.utc.to_formatted_s(:db))
  end

  def discard_tokens
    self.valid_tokens.each do |token| 
      token.discard
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
    self.players_lock_types(true).each do |players_lock_type|
      result << players_lock_type.lock_type.name if players_lock_type.status == 'active'
    end
    result
  end

  def out_of_daily_limit?(amount, trans_type, casino_id)
    amount > remain_trans_amount(trans_type, casino_id)
  end

  def remain_trans_amount(trans_type, casino_id)
    limit = ConfigHelper.new(casino_id).send "daily_#{trans_type}_limit"
    limit - trans_amount(trans_type, casino_id)
  end

  def trans_amount(trans_type, casino_id)
    accounting_date = AccountingDate.current(casino_id)
    player_transaction_daily_amount = PlayerTransaction.daily_transaction_amount_by_player(self, accounting_date, trans_type, casino_id)
    kiosk_transaction_daily_amount = KioskTransaction.daily_transaction_amount_by_player(self, accounting_date, trans_type, casino_id)
    player_transaction_daily_amount + kiosk_transaction_daily_amount
  end

  class << self
    def create_by_params(params, mp_create)
      verify_player_info(params)

      player = new
      player.card_id = params[:card_id]
      player.member_id = params[:member_id]
      player.first_name = params[:first_name].downcase if params[:first_name]
      player.last_name = params[:last_name].downcase if params[:first_name]
      player.licensee_id = params[:licensee_id]
      player.test_mode_player = params[:test_mode_player]
      player.currency_id = Currency.find_by_name('HKD').id
      player.status = STATUS_NORMAL
      begin
        player.save!
      rescue ActiveRecord::RecordInvalid => ex
        duplicated_filed = ex.record.errors.keys.first.to_s
        raise CreatePlayer::DuplicatedFieldError, "CreatePlayer::DuplicatedFieldError, duplicated_filed : #{duplicated_filed} (#{player[duplicated_filed.to_sym]})"
      end

      if !mp_create
        player_status = params[:blacklist] ? STATUS_LOCKED : STATUS_NORMAL
        casino = Casino.where(:licensee_id => player.licensee_id).first
        get_requester_helper(casino.id).create_mp_player(player.id, player.member_id, player.card_id, player_status, player.test_mode_player, player.licensee_id, player.currency_id, params[:blacklist])
      end
      #new_player_deposit(player) if params[:test_mode_player] == 0 || params[:test_mode_player] == false
      player
    end

    def new_player_deposit(player)
      amt = YAML.load_file("#{SELF_ROOT}/config/initial_balance.yml")[Rails.env][player.licensee_id]
      casino = Casino.where(:licensee_id => player.licensee_id).first
      raise Remote::CasinoNotFound if casino.nil?

      get_requester_helper(casino.id).internal_deposit(player.member_id, amt[:initial_balance].to_s, nil, 'promotion_deposit', casino.id, 'INITPRO', 'system')
    end

    def get_requester_helper(casino_id)
      requester_config_file = "#{Rails.root}/config/requester_config.yml"
      licensee_id = Casino.get_licensee_id_by_casino_id(casino_id)
      requester_facotry = Requester::RequesterFactory.new(requester_config_file, Rails.env, casino_id, licensee_id, nil)
      RequesterHelper.new(requester_facotry)
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

    def find_by_id_type_and_number(id_type, id_number)
      self.send "find_by_#{id_type}", id_number
    end

    def create_inactivate(player_info)
      player = Player.new(:member_id => player_info[:member_id], :card_id => player_info[:card_id], :status => 'not_activate', :currency_id => Currency.first.id)
    end

    def update_info(player_info, mp_create)
      return false if player_info.nil? || player_info[:member_id].nil? || player_info[:card_id].nil? || player_info[:pin_status].nil?
      player = Player.find_by_member_id_and_licensee_id(player_info[:member_id], player_info[:licensee_id])
      player = Player.create_by_params(player_info, mp_create) if player == nil && player_info[:pin_status] != 'blank'
      is_discard_tokens = player_info[:pin_status] == 'reset'
      if player_info[:card_id] != player.card_id
        player.card_id = player_info[:card_id]
        player.save
        is_discard_tokens = true
      end
      player.discard_tokens if is_discard_tokens
      if player_info[:blacklist]
        player.lock_account!('blacklist')
      else
        player.unlock_account!('blacklist')
      end
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

    def verify_player_info(params)
      card_id = params[:card_id]
      member_id = params[:member_id]
      first_name = params[:first_name]
      last_name = params[:last_name]

      raise CreatePlayer::ParamsError, "card_id_length_error" if card_id.nil? || card_id.blank?
      raise CreatePlayer::ParamsError, "member_id_length_error" if member_id.nil? || member_id.blank?
      # raise CreatePlayer::ParamsError, "first_name_blank_error" if first_name.nil? || first_name.blank?
      # raise CreatePlayer::ParamsError, "last_name_blank_error" if last_name.nil? || last_name.blank?

      raise CreatePlayer::ParamsError, "card_id_only_number_allowed_error" if !str_is_i?(card_id)
      raise CreatePlayer::ParamsError, "member_id_only_number_allowed_error" if !str_is_i?(member_id)
    end

    def find_by_member_id_and_casino_id(member_id, casino_id)
      licensee_id = Casino.get_licensee_id_by_casino_id(casino_id)
      find_by_member_id_and_licensee_id(member_id, licensee_id)
    end

    def find_by_card_id_and_casino_id(card_id, casino_id)
      licensee_id = Casino.get_licensee_id_by_casino_id(casino_id)
      find_by_card_id_and_licensee_id(card_id, licensee_id)
    end
    
    def find_by_id_type_and_id_number(id_type, id_number, licensee_id)
      if id_type == :member_id
        Player.find_by_member_id_and_licensee_id(id_number, licensee_id)
      else
        Player.find_by_card_id_and_licensee_id(id_number, licensee_id)
      end
    end
  end
end
