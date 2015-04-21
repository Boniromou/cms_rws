require 'spec_helper'

include Hood

RSpec.describe Cashier, "cancel bet" do
  include CashierSpecHelper

  before(:each) do
    clean_db
    Currency.dataset.insert(:id=>1,:name=>'RMB',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Property.dataset.insert(:id=>1000,:name=>'p',:secret_key=>'s',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Player.dataset.insert(:id=>123,:login_name=>'abc',:currency_id=>1,:property_id=>1000,:shareholder=>'holder',:balance=>20010,
                          :updated_at=>Time.now.utc,:lock_state=>'unlocked',:created_at=>Time.now.utc)
  end

  it "MissingRequiredParameters" do
    ib = {:trans_date=>'',:round_id=>'',:game_id=>'',:internal_game_id=>'',:session_token=>''}
    ob = cancel_bet(ib)
    expect(ob[:error_code]).to eq('MissingRequiredParameters')
    expect(ob[:message]).to include("login_name")
    expect(ob[:message]).to include("ref_trans_id")
    expect(ob[:message]).to include("bet_amt")
    expect(ob[:message]).to include("trans_date")
    expect(ob[:message]).to include("round_id")
    expect(ob[:message]).to include("game_id")
    expect(ob[:message]).to include("internal_game_id")
    expect(ob[:message]).to include("session_token")
  end

  it "InvalidAmount" do
    ib = {:bet_amt=>0,:login_name=>'abc',:ref_trans_id=>'T1'}
    ob = cancel_bet(ib)
    expect(ob[:error_code]).to eq('InvalidAmount')
  end

  it "CancelBetNotExist" do
    ib = {:bet_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    ob = cancel_bet(ib)
    expect(ob[:error_code]).to eq('CancelBetNotExist')
    t = CancelBetTransaction[:ref_trans_id=>'-T1']
    expect(t[:bet_amt]).to eq 100.1*100
    expect(t[:aasm_state]).to eq 'rejected'
    expect(t[:before_balance]).to eq 20010
    expect(t[:after_balance]).to eq 20010
  end

  it "OK" do
    t = Time.now
    ib = {:bet_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    bet(ib)
    ib = {:bet_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1',:round_id=>'123',:game_id=>'1',:internal_game_id=>'1001'}
    ob = cancel_bet(ib)
    expect(ob[:error_code]).to eq('OK')
    expect(ob[:before_balance]).to eq 100
    expect(ob[:balance]).to eq 200.1
    p = Player[123]
    expect(p[:balance]).to eq 200.1*100
    expect(p[:played_at].to_i).to be >= t.to_i
    t = CancelBetTransaction[:ref_trans_id=>'-T1']
    expect(t[:bet_amt]).to eq 100.1*100
    expect(t[:aasm_state]).to eq 'completed'
    expect(t[:before_balance]).to eq 100*100
    expect(t[:after_balance]).to eq 200.1* 100
    expect(t[:round_id]).to eq 123
    expect(t[:external_game_id]).to eq 1
    expect(t[:internal_game_id]).to eq 1001
  end

  it "OK - AlreadyProcessed" do
    ib = {:bet_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    bet(ib)
    ib = {:bet_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    cancel_bet(ib)
    ib = {:bet_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    ob = cancel_bet(ib)
    expect(ob[:error_code]).to eq('AlreadyProcessed')
    p = Player[123]
    expect(p[:balance]).to eq 200.1*100
  end

  it "CancelBetNotExist - AlreadyProcessed" do
    ib = {:bet_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    cancel_bet(ib)
    ib = {:bet_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    ob = cancel_bet(ib)
    expect(ob[:error_code]).to eq('AlreadyProcessed')
    p = Player[123]
    expect(p[:balance]).to eq 200.1*100
  end

  it "CancelBetNotMatch" do
    ib = {:bet_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    bet(ib)
    ib = {:bet_amt=>100.11,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    ob = cancel_bet(ib)
    expect(ob[:error_code]).to eq('CancelBetNotMatch')
  end

end
