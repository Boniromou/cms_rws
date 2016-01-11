require 'spec_helper'

include Hood

RSpec.describe Cashier, "bet" do
  include CashierSpecHelper

  before(:each) do
    clean_db
    Currency.dataset.insert(:id=>1,:name=>'RMB',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Property.dataset.insert(:id=>1000,:name=>'p',:secret_key=>'s',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Player.dataset.insert(:id=>123,:login_name=>'abc',:currency_id=>1,:property_id=>1000,:shareholder=>'holder',:balance=>20010,
                          :credit_balance=>0,
                          :updated_at=>Time.now.utc,:lock_state=>'unlocked',:created_at=>Time.now.utc)
    allow_any_instance_of(ValidateTokenService).to receive(:validate_token).and_return(true)
    allow(Hood::CONFIG).to receive(:is_validate_token).and_return(true)
  end

  it "MissingRequiredParameters" do
    ib = {:trans_date=>'',:round_id=>'',:game_id=>'',:internal_game_id=>'',:session_token=>''}
    ob = bet(ib)
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
    ob = bet(ib)
    expect(ob[:error_code]).to eq('InvalidAmount')
  end

  it "AmountNotEnough" do
    ib = {:bet_amt=>200.12,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    ob = bet(ib)
    expect(ob[:error_code]).to eq('AmountNotEnough')
    expect(ob[:balance]).to eq 200.1
    t = BetTransaction[:ref_trans_id=>'T1']
    expect(t).to be_nil
  end

  it "OK" do
    t = Time.now
    ib = {:bet_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1',:round_id=>'123',:game_id=>'1',:internal_game_id=>'1001'}
    ob = bet(ib)
    expect(ob[:error_code]).to eq('OK')
    expect(ob[:before_balance]).to eq 200.1
    expect(ob[:balance]).to eq 100
    p = Player[123]
    expect(p[:balance]).to eq 100*100
    expect(p[:played_at].to_i).to be >= t.to_i
    t = BetTransaction[:ref_trans_id=>'T1']
    expect(t[:bet_amt]).to eq 100.1*100
    expect(t[:aasm_state]).to eq 'completed'
    expect(t[:round_id]).to eq 123
    expect(t[:external_game_id]).to eq 1
    expect(t[:internal_game_id]).to eq 1001
  end

  it "AlreadyCancelled" do
    CancelBetTransaction.create(:ref_trans_id=>'T1',:aasm_state=>'rejected',:bet_amt=>100.1,:player_id=>123,:property_id=>1000)
    ib = {:bet_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    ob = bet(ib)
    expect(ob[:error_code]).to eq('AlreadyCancelled')
  end
  
  it "InvalidSessionToken" do
    Hood::CONFIG.property_keys={}
    validate_token_fail_response = '{"error_code":"InvalidSessionToken", "error_msg":"Session token is invalid."}'
    allow_any_instance_of(ValidateTokenService).to receive(:validate_token).and_call_original
    allow_any_instance_of(Hood::LaxRequester).to receive(:send_request).and_return(validate_token_fail_response)
    ib = {:bet_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1',:round_id=>'123',:game_id=>'1',:internal_game_id=>'1001'}
    ob = bet(ib)
    expect(ob[:error_code]).to eq('InvalidSessionToken')
  end

  context "ref_trans_id exist" do
    before(:each) do
      ib = {:bet_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
      bet(ib)
    end

    it "ALreadyProcessed" do
      ib = {:bet_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
      ob = bet(ib)
      expect(ob[:error_code]).to eq('AlreadyProcessed')
      expect(ob[:before_balance]).to eq 200.1
      expect(ob[:balance]).to eq 100.0
    end

    it "DuplicateTrans" do
      ib = {:bet_amt=>100.2,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
      bet(ib)
    end

  end

end
