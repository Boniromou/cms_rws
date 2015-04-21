require 'spec_helper'

include Hood

RSpec.describe Cashier, "result" do
  include CashierSpecHelper

  before(:each) do
    clean_db
    Currency.dataset.insert(:id=>1,:name=>'RMB',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Property.dataset.insert(:id=>1000,:name=>'p',:secret_key=>'s',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Player.dataset.insert(:id=>123,:login_name=>'abc',:currency_id=>1,:property_id=>1000,:shareholder=>'holder',:balance=>0,
                          :updated_at=>Time.now.utc,:lock_state=>'unlocked',:created_at=>Time.now.utc)
  end

  it "MissingRequiredParameters" do
    ib = {:trans_date=>'',:round_id=>'',:game_id=>'',:internal_game_id=>'',:session_token=>'',:win_amt=>''}
    ob = result(ib)
    expect(ob[:error_code]).to eq('MissingRequiredParameters')
    expect(ob[:message]).to include("login_name")
    expect(ob[:message]).to include("ref_trans_id")
    expect(ob[:message]).to include("payout_amt")
    expect(ob[:message]).to include("trans_date")
    expect(ob[:message]).to include("win_amt")
    expect(ob[:message]).to include("round_id")
    expect(ob[:message]).to include("game_id")
    expect(ob[:message]).to include("internal_game_id")
    expect(ob[:message]).to include("session_token")
  end

  it "MissingRequiredParameters for jackpot parameters" do
    ib = {:payout_amt=>0,:login_name=>'abc',:ref_trans_id=>'T1',:jp_win_id=>'jpwin1'}
    ob = result(ib)
    expect(ob[:error_code]).to eq('MissingRequiredParameters')
    expect(ob[:message]).to include("jc_jp_con_amt")
    expect(ob[:message]).to include("jc_jp_win_amt")
    expect(ob[:message]).to include("pc_jp_con_amt")
    expect(ob[:message]).to include("pc_jp_win_amt")
    expect(ob[:message]).to include("jp_win_lev")
    expect(ob[:message]).to include("jp_direct_pay")
  end

  it "InvalidAmount" do
    ib = {:payout_amt=>-0.1,:login_name=>'abc',:ref_trans_id=>'T1'}
    ob = result(ib)
    expect(ob[:error_code]).to eq('InvalidAmount')
  end

  it "OK" do
    t = Time.now
    ib = {:payout_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1',:win_amt=>'1.1',:round_id=>'123',:game_id=>'1',:internal_game_id=>'1001',:jc_jp_con_amt=>'1.23456',:jc_jp_win_amt=>'9.87654',:pc_jp_con_amt=>'1.23',:pc_jp_win_amt=>'9.87',:jp_win_lev=>'1',:jp_win_id=>'JPW1',:jp_direct_pay=>'0'}
    ob = result(ib)
    expect(ob[:error_code]).to eq('OK')
    expect(ob[:before_balance]).to eq 0
    expect(ob[:balance]).to eq 100.1
    p = Player[123]
    expect(p[:balance]).to eq 100.1*100
    expect(p[:played_at].to_i).to be >= t.to_i
    t = ResultTransaction[:ref_trans_id=>'T1']
    expect(t[:payout_amt]).to eq 100.1*100
    expect(t[:aasm_state]).to eq 'completed'
    expect(t[:win_amt]).to eq 110
    expect(t[:round_id]).to eq 123
    expect(t[:external_game_id]).to eq 1
    expect(t[:internal_game_id]).to eq 1001
    expect(t[:jc_jp_con_amt]).to eq 1.23456
    expect(t[:jc_jp_win_amt]).to eq 9.87654
    expect(t[:pc_jp_con_amt]).to eq 1.23
    expect(t[:pc_jp_win_amt]).to eq BigDecimal.new("9.87")
    expect(t[:jp_win_lev]).to eq 1
    expect(t[:jp_win_id]).to eq 'JPW1'
    expect(t[:jp_direct_pay]).to eq false
  end

  it "OK with jp_direct_pay" do
    ib = {:payout_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1',:win_amt=>'1.1',:round_id=>'123',:game_id=>'1',:internal_game_id=>'1001',:jc_jp_con_amt=>'1.23456',:jc_jp_win_amt=>'9.87654',:pc_jp_con_amt=>'1.23',:pc_jp_win_amt=>'9.87',:jp_win_lev=>'1',:jp_win_id=>'JPW1',:jp_direct_pay=>'1'}
    ob = result(ib)
    expect(ob[:error_code]).to eq('OK')
    expect(ob[:before_balance]).to eq 0
    expect(ob[:balance]).to eq 109.97
    p = Player[123]
    expect(p[:balance]).to eq 109.97*100
    t = ResultTransaction[:ref_trans_id=>'T1']
    expect(t[:jp_direct_pay]).to eq true
  end

  context "ref_trans_id exist" do
    before(:each) do
      ib = {:payout_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
      result(ib)
    end

    it "AlreadyProcessed" do
      ib = {:payout_amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
      ob = result(ib)
      expect(ob[:error_code]).to eq('AlreadyProcessed')
      expect(ob[:before_balance]).to eq 0
      expect(ob[:balance]).to eq 100.1
    end

    it "DuplicateTrans" do
      ib = {:payout_amt=>100.2,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
      ob = result(ib)
      expect(ob[:error_code]).to eq('DuplicateTrans')
    end

  end

end
