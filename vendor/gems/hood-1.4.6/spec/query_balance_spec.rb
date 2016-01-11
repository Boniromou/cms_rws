require 'spec_helper'

include Hood

describe Cashier, "query balance" do
  include CashierSpecHelper

  before(:each) do
    clean_db
    Currency.dataset.insert(:id=>1,:name=>'RMB',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Property.dataset.insert(:id=>1000,:name=>'p',:secret_key=>'k',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Property.dataset.insert(:id=>1001,:name=>'p',:secret_key=>'k',:credit_mode=>'partial',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Player.dataset.insert(:id=>100,:login_name=>'player1',:currency_id=>1,:property_id=>1000,:shareholder=>'holder1',
                          :balance=>20010,:updated_at=>Time.now.utc,:lock_state=>'unlocked',:created_at=>Time.now.utc)
    Player.dataset.insert(:id=>101,:login_name=>'player2',:currency_id=>1,:property_id=>1000,:shareholder=>'holder1',
                          :balance=>10012,:updated_at=>Time.now.utc,:lock_state=>'unlocked',:created_at=>Time.now.utc)
    Player.dataset.insert(:id=>102,:login_name=>'player1',:currency_id=>1,:property_id=>1001,:shareholder=>'holder1',
                          :balance=>13450,:updated_at=>Time.now.utc,:lock_state=>'unlocked',:created_at=>Time.now.utc)
    Player.dataset.insert(:id=>103,:login_name=>'player2',:currency_id=>1,:property_id=>1001,:shareholder=>'holder1',
                          :balance=>13450,:credit_balance=>52000,:credit_expired_at=>'2099-10-10 00:00:00',:updated_at=>Time.now.utc,:lock_state=>'unlocked',:created_at=>Time.now.utc)
    Player.dataset.insert(:id=>104,:login_name=>'player3',:currency_id=>1,:property_id=>1001,:shareholder=>'holder1',
                          :balance=>13450,:credit_balance=>52000,:credit_expired_at=>'1099-10-10 00:00:00',
                          :updated_at=>Time.now.utc,:lock_state=>'unlocked',:created_at=>Time.now.utc)

  end

  context "query_player_balance" do
    it "MissingRequiredParameters" do
      ib = {:property_id=>1000}
      ob = query_player_balance(ib)
      expect(ob[:error_code]).to eq('MissingRequiredParameters')
      expect(ob[:message]).to include 'login_name'
    end

    it "OK" do
      ib = {:property_id=>1000,:login_name=>'player2'}
      ob = query_player_balance(ib)
      expect(ob[:error_code]).to eq('OK')
      expect(ob[:balance]).to eq(100.12)
    end

    it "InvalidLoginName" do
      ib = {:property_id=>1000,:login_name=>'noplayer'}
      ob = query_player_balance(ib)
      expect(ob[:error_code]).to eq('InvalidLoginName')
    end

    it "OK with credit enabled" do
      ib = {:property_id=>1001,:login_name=>'player1'}
      ob = query_player_balance(ib)
      expect(ob[:error_code]).to eq('OK')
      expect(ob[:balance]).to eq 134.5
      expect(ob[:credit_balance]).to eq 0
      expect(ob[:credit_expired_at]).to eq nil
    end

    it "OK with credit balance" do
      ib = {:property_id=>1001,:login_name=>'player2'}
      ob = query_player_balance(ib)
      expect(ob[:error_code]).to eq('OK')
      expect(ob[:balance]).to eq 134.5
      expect(ob[:credit_balance]).to eq 520.0
      expect(ob[:credit_expired_at]).to eq '2099-10-10 08:00:00'
    end

    it "OK with credit balance already expired" do
      ib = {:property_id=>1001,:login_name=>'player3'}
      ob = query_player_balance(ib)
      expect(ob[:error_code]).to eq('OK')
      expect(ob[:balance]).to eq 134.5
      expect(ob[:credit_balance]).to eq 0
      p = Player[104]
      expect(p[:credit_balance]).to eq 0
      t = CreditAutoExpireTransaction.first
      expect(t[:credit_before_balance]).to eq 52000
      expect(t[:credit_after_balance]).to eq 0
    end

  end

  context "query_player_balances" do
    it "MissingRequiredParameters" do
      ib = {:property_id=>1000}
      ob = query_player_balances(ib)
      expect(ob[:error_code]).to eq('MissingRequiredParameters')
      expect(ob[:message]).to include 'login_names'
    end

    it "OK" do
      ib = {:property_id=>1000,:login_names=>'player1,PLAYER2'}
      ob = query_player_balances(ib)
      expect(ob[:error_code]).to eq('OK')
      expect(ob[:players].length).to eq 2
      expect(ob[:players]).to include({:login_name=>'player1',:balance=>200.10})
      expect(ob[:players]).to include({:login_name=>'player2',:balance=>100.12})
    end

    it "ignore non-existing login_names" do
      ib = {:property_id=>1000,:login_names=>'player1,player3'}
      ob = query_player_balances(ib)
      expect(ob[:error_code]).to eq('OK')
      expect(ob[:players].length).to eq 1
      expect(ob[:players]).to include({:login_name=>'player1',:balance=>200.10})
    end
  end

  context "query_vendor_total_balance" do
=begin
    it "MissingRequiredParameters" do
      ib = {:property_id=>1000}
      ob = query_vendor_total_balance(ib)
      expect(ob[:error_code]).to eq('MissingRequiredParameters')
      expect(ob[:message]).to include 'vendor'
    end
=end
    it "OK" do
      ib = {:property_id=>1000,:vendor=>'holder1'}
      ob = query_vendor_total_balance(ib)
      expect(ob[:error_code]).to eq('OK')
      expect(ob[:total_balance]).to eq 300.22
    end
  end

end
