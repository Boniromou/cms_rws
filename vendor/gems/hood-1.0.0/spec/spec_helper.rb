require 'hood'
require 'sequel'
require 'logger'

Hood.connect_db('mysql2://hood:hood@mo-int-iwms-vdb01.rnd.laxino.com/hood_iwms_test',:logger=>Logger.new('spec_sql.log'))
#Sequel.identifier_input_method = :downcase
#Hood.connect_db('tinytds://hood:hood@mo-mgm-vdb01.mo.laxino.com:1443/hood_iwms_integration',:logger=>Logger.new('spec_sql.log'))


def clean_db
  WalletTransaction.dataset.delete
  RoundTransaction.dataset.delete
  Player.dataset.delete
  Property.dataset.delete
  Currency.dataset.delete
end

# disable log when run rspec
include Hood::Loggable
logger.level = Logger::FATAL

module CashierSpecHelper

  def create_player(ib)
    ib[:_event_name] = :create_player
    do_action(ib)
  end

  def deposit(ib)
    ib[:_event_name] = :deposit
    do_action(ib)
  end

  def withdraw(ib)
    ib[:_event_name] = :withdraw
    do_action(ib)
  end

  def bet(ib)
    ib[:_event_name] = :bet
    fill_round_trans_ib(ib)
    do_action(ib)
  end

  def cancel_bet(ib)
    ib[:_event_name] = :cancel_bet
    fill_round_trans_ib(ib)
    do_action(ib)
  end

  def result(ib)
    ib[:_event_name] = :result
    fill_round_trans_ib(ib)
    ib[:win_amt] = '0.0' unless ib[:win_amt]
    do_action(ib)
  end

  def query_player_balance(ib)
    ib[:_event_name] = :query_player_balance
    do_action(ib)
  end

  def query_player_balances(ib)
    ib[:_event_name] = :query_player_balances
    do_action(ib)
  end

  def query_vendor_total_balance(ib)
    ib[:_event_name] = :query_vendor_total_balance
    do_action(ib)
  end

  def query_system_time(ib)
    ib[:_event_name] = :query_system_time
    do_action(ib)
  end

  def query_wallet_transactions(ib)
    ib[:_event_name] = :query_wallet_transactions
    do_action(ib)
  end

  def query_round_transactions(ib)
    ib[:_event_name] = :query_round_transactions
    do_action(ib)
  end

  protected
  def do_action(ib)
    fill_ib(ib)
    p ib
    ob = Cashier.instance.update(ib)
    p ob
    ob
  end

  def fill_ib(ib)
    set_default_property(ib)
    ib[:trans_date] = "2000-01-01 00:00:00" unless ib[:trans_date]
  end

  def fill_round_trans_ib(ib)
    ib[:round_id] = '123' unless ib[:round_id]
    ib[:game_id] = '1' unless ib[:game_id]
    ib[:internal_game_id] = '1001' unless ib[:internal_game_id]
    ib[:session_token] = "token" unless ib[:session_token]
  end

  def set_default_property(ib)
    ib[:property_id] = 1 unless ib[:property_id]
    unless Property[ib[:property_id]]
      Property.dataset.insert({:id=>ib[:property_id],:name=>'TestP',:secret_key=>'k',:created_at=>Time.now.utc,:updated_at=>Time.now.utc})
    end
  end


end
