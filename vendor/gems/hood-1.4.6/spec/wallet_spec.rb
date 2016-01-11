require 'spec_helper'

include Hood

RSpec.describe Cashier, "wallet" do
  include CashierSpecHelper

  before(:each) do
    clean_db
    Currency.dataset.insert(:id=>1,:name=>'RMB',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Property.dataset.insert(:id=>1000,:name=>'p',:secret_key=>'s',:credit_mode=>'partail',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Player.dataset.insert(:id=>123,:login_name=>'abc',:currency_id=>1,:property_id=>1000,:shareholder=>'holder',:balance=>0,
                          :credit_balance=>0,
                          :updated_at=>Time.now.utc,:lock_state=>'unlocked',:created_at=>Time.now.utc)
    allow_any_instance_of(ValidateTokenService).to receive(:validate_token).and_return(true)
    allow(Hood::CONFIG).to receive(:is_validate_token).and_return(true)
  end

  it "AmountNotEnough" do
    ib = {:amt=>10,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    deposit(ib)
    ib = {:credit_amt=>50,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1',:credit_expired_at=>"2099-10-10 00:00:00"}
    credit_deposit(ib)
    ib = {:bet_amt=>20,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    ob = bet(ib)
    expect(ob[:error_code]).to eq('AmountNotEnough')
  end

  it "bet only using credit, cancel bet" do
    ib = {:amt=>100,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    deposit(ib)
    ib = {:credit_amt=>50,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1',:credit_expired_at=>"2099-10-10 00:00:00"}
    credit_deposit(ib)
    ib = {:bet_amt=>20,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    bet(ib)
    p = Player[123]
    expect(p[:balance]).to eq 100*100
    expect(p[:credit_balance]).to eq 30 * 100

    ib = {:bet_amt=>20,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    cancel_bet(ib)
    p = Player[123]
    expect(p[:balance]).to eq 100*100
    expect(p[:credit_balance]).to eq 50 * 100
    expect(p[:credit_expired_at]).to eq Time.parse('2099-10-10 00:00:00 +08:00')
  end

  it "bet using both credit and cash, cancel bet" do
    ib = {:amt=>100,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    deposit(ib)
    ib = {:credit_amt=>50,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1',:credit_expired_at=>"2099-10-10 00:00:00"}
    credit_deposit(ib)
    ib = {:bet_amt=>70,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    bet(ib)
    bt = BetTransaction[:ref_trans_id=>'T1',:property_id=>1000]
    expect(bt[:bet_amt]).to eq 20*100
    expect(bt[:credit_bet_amt]).to eq 50*100
    expect(bt[:total_bet_amt]).to eq 70*100
    p = Player[123]
    expect(p[:balance]).to eq 80*100
    expect(p[:credit_balance]).to eq 0

    ib = {:bet_amt=>10,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T2'}
    bet(ib)
    ib = {:bet_amt=>70,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    cancel_bet(ib)
    cbt = CancelBetTransaction[:ref_trans_id=>'T1',:property_id=>1000]
    expect(cbt[:bet_amt]).to eq 20*100
    expect(cbt[:credit_bet_amt]).to eq 50*100
    expect(cbt[:total_bet_amt]).to eq 70*100

    p = Player[123]
    expect(p[:balance]).to eq 90*100
    expect(p[:credit_balance]).to eq 50*100
  end

  it "bet with credit, remain credit expire, cancel bet" do
    ib = {:amt=>100,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    deposit(ib)
    ib = {:credit_amt=>50,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1',:credit_expired_at=>"2099-10-10 00:00:00"}
    credit_deposit(ib)
    ib = {:bet_amt=>20,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    bet(ib)
    ib = {:credit_amt=>30,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    credit_expire(ib)
    ib = {:bet_amt=>20,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    cancel_bet(ib)
    p = Player[123]
    expect(p[:balance]).to eq 100*100
    expect(p[:credit_balance]).to eq 20*100
    sleep 1
    ib ={:login_name=>'abc',:property_id=>1000}
    ob = query_player_balance(ib)
    p = Player[123]
    expect(p[:credit_balance]).to eq 0
  end

  context "credit already expired" do
    before(:each) do
      ib = {:amt=>100,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
      deposit(ib)
      ib = {:credit_amt=>50,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1',:credit_expired_at=>"2000-10-10 00:00:00"}
      credit_deposit(ib)
    end

    it "query balance" do
      ib = {:login_name=>'abc',:property_id=>1000}
      query_player_balance(ib)
      p = Player[123]
      expect(p[:credit_balance]).to eq 0
    end

    it "deposit credit" do
      ib = {:credit_amt=>150,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T2',:credit_expired_at=>"2099-10-10 00:00:00"}
      ob = credit_deposit(ib)
      expect(ob[:credit_after_balance]).to eq 150
      p = Player[123]
      expect(p[:credit_balance]).to eq 150 * 100
    end

    it "deposit" do
      ib = {:amt=>150,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T2'}
      ob = deposit(ib)
      expect(ob[:credit_after_balance]).to eq 0
      p = Player[123]
      expect(p[:credit_balance]).to eq 0
    end

    it "withdraw" do
      ib = {:amt=>150,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T2'}
      ob = withdraw(ib)
      p = Player[123]
      expect(p[:credit_balance]).to eq 0
    end

  end
end
