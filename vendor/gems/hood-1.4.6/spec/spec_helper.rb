require 'hood'
require 'sequel'
require 'logger'

Hood.connect_db('mysql2://hood:hood@mo-int-iwms-vdb01.rnd.laxino.com/hood_iwms_test',:logger=>Logger.new('spec_sql.log'))
#Hood.connect_db('tinytds://hood:hood@mo-mgm-vdb01.mo.laxino.com:1443/hood_iwms_integration',:logger=>Logger.new('spec_sql.log'))


def clean_db
  CashierTransaction.dataset.delete
  RoundTransaction.dataset.delete
  Player.dataset.delete
  Property.dataset.delete
  Currency.dataset.delete

  Property.reset
end

# disable log when run rspec
include Hood::Loggable
logger.level = Logger::FATAL

module CashierSpecHelper

  def create_player(ib)
    ib[:_event_name] = :create_player
    do_action(ib)
  end

  def create_internal_player(ib)
    ib[:_event_name] = :create_internal_player
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

  def void_deposit(ib)
    ib[:_event_name] = :void_deposit
    do_action(ib)
  end

  def void_withdraw(ib)
    ib[:_event_name] = :void_withdraw
    do_action(ib)
  end

  def credit_deposit(ib)
    ib[:_event_name] = :credit_deposit
    do_action(ib)
  end

  def credit_expire(ib)
    ib[:_event_name] = :credit_expire
    do_action(ib)
  end

  def credit_auto_expire(ib)
    ib[:_event_name] = :credit_auto_expire
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

  def query_cashier_transactions(ib)
    ib[:_event_name] = :query_cashier_transactions
    do_action(ib)
  end

  def query_result_transactions(ib)
    ib[:_event_name] = :query_result_transactions
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
    if ib[:_event_name] != :credit_auto_expire
      ib[:trans_date] = "2020-01-01 00:00:00" unless ib[:trans_date]
    end
  end

  def fill_round_trans_ib(ib)
    ib[:round_id] = '123' unless ib[:round_id]
    ib[:game_id] = '1' unless ib[:game_id]
    ib[:internal_game_id] = '1001' unless ib[:internal_game_id]
    ib[:session_token] = "token" unless ib[:session_token]
    ib[:machine_token] = "machine_token" unless ib[:machine_token]
    ib[:total_bet_amt] = 100
  end

  def set_default_property(ib)
    ib[:property_id] = 1 unless ib[:property_id]
    unless Property[ib[:property_id]]
      Property.dataset.insert({:id=>ib[:property_id],:name=>'TestP',:secret_key=>'k',:created_at=>Time.now.utc,:updated_at=>Time.now.utc})
    end
  end


end
