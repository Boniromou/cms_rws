require 'spec_helper'

include Hood

describe Cashier, "query transactions" do
  include CashierSpecHelper

  before(:each) do
    clean_db
    Currency.dataset.insert(:id=>1,:name=>'RMB',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Property.dataset.insert(:id=>1000,:name=>'p',:secret_key=>'s',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Player.dataset.insert(:id=>100,:login_name=>'player1',:currency_id=>1,:property_id=>1000,:shareholder=>'holder1',
                          :balance=>20010,:updated_at=>Time.now.utc,:lock_state=>'unlocked',:created_at=>Time.now.utc)
    Player.dataset.insert(:id=>102,:login_name=>'player2',:currency_id=>1,:property_id=>1000,:shareholder=>'holder1',
                          :balance=>13450,:updated_at=>Time.now.utc,:lock_state=>'unlocked',:created_at=>Time.now.utc)
    allow(Property).to receive(:get_time_zone).and_return("+09:00")
  end

  it "query_system_time" do
    ib = {:property_id=>1000}
    ob = query_system_time(ib)
    expect(ob[:error_code]).to eq 'OK'
    expect(ob[:time]).not_to be_nil
  end

  context "query_cashier_transactions" do
    it "MissingRequiredParameters" do
      ib = {:property_id=>1000}
      ob = query_cashier_transactions(ib)
      expect(ob[:error_code]).to eq('MissingRequiredParameters')
      expect(ob[:message]).to include 'from_time'
      expect(ob[:message]).to include 'to_time'
    end

    it "InvalidTimeRange - from_time > to_time" do
      ib = {:property_id=>1000,:from_time=>'2014-09-11 21:00:00',:to_time=>'2014-09-10 22:00:00'}
      ob = query_cashier_transactions(ib)
      expect(ob[:error_code]).to eq('InvalidTimeRange')
    end
    
    it "InvalidTimeRange - to_time too large" do
      now = Time.parse('2014-09-11 21:59:59+09:00')
      allow(Time).to receive(:now).and_return(now)
      ib = {:property_id=>1000,:from_time=>'2014-09-11 21:00:00',:to_time=>'2014-09-11 22:00:00'}
      ob = query_cashier_transactions(ib)
      expect(ob[:error_code]).to eq('InvalidTimeRange')
    end

    it "InvalidTimeRange - from_time too early" do
      now = Time.parse('2014-09-17 21:00:00+09:00')
      allow(Time).to receive(:now).and_return(now)
      ib = {:property_id=>1000,:from_time=>'2014-09-09 21:00:00',:to_time=>'2014-09-09 22:00:00'}
      ob = query_cashier_transactions(ib)
      expect(ob[:error_code]).to eq('InvalidTimeRange')
    end

    it "InvalidTimeRange - range is too large" do
      now = Time.parse('2014-09-10 21:00:00+09:00')
      allow(Time).to receive(:now).and_return(now)
      ib = {:property_id=>1000,:from_time=>'2014-09-09 21:00:00',:to_time=>'2014-09-09 22:00:01'}
      ob = query_cashier_transactions(ib)
      expect(ob[:error_code]).to eq('InvalidTimeRange')
    end

    it "OK" do
      now = Time.parse('2014-09-11 00:00:00+09:00')
      allow(Time).to receive(:now).and_return(now)
      CashierTransaction.create(:ref_trans_id=>'wt1',:amt=>12345,:aasm_state=>'completed',:before_balance=>0,:after_balance=>12345,:trans_type=>'deposit',:property_id=>1000,:player_id=>100,:created_at=>'2014-09-09 12:00:00',:trans_date=>'2014-09-09 12:25:00')
      CashierTransaction.create(:ref_trans_id=>'wt2',:amt=>54321,:aasm_state=>'completed',:before_balance=>54321,:after_balance=>0,:trans_type=>'withdraw',:property_id=>1000,:player_id=>100,:created_at=>'2014-09-09 12:30:00',:trans_date=>'2014-09-09 12:25:00')
      CashierTransaction.create(:ref_trans_id=>'wt3',:amt=>12345,:aasm_state=>'completed',:before_balance=>0,:after_balance=>12345,:trans_type=>'deposit',:property_id=>1000,:player_id=>100,:created_at=>'2014-09-10 13:00:00',:trans_date=>'2014-09-10 12:25:00')
      
      ib = {:property_id=>1000,:from_time=>'2014-09-09 21:00:00',:to_time=>'2014-09-09 22:00:00'}
      ob = query_cashier_transactions(ib)
      expect(ob[:error_code]).to eq('OK')
      transactions = ob[:transactions]
      expect(transactions.length).to eq 2
      wt1 = transactions.find {|t| t[:ref_trans_id]=='wt1'}
      expect(wt1[:trans_type]).to eq 'deposit'
      expect(wt1[:status]).to eq 'completed'
      expect(wt1[:amt]).to eq 123.45
      expect(wt1[:before_balance]).to eq 0
      expect(wt1[:after_balance]).to eq 123.45
      expect(wt1[:login_name]).to eq 'player1'
      expect(wt1[:trans_date]).to eq '2014-09-09 21:00:00'
      wt2 = transactions.find {|t| t[:ref_trans_id]=='wt2'}
      expect(wt2[:trans_type]).to eq 'withdraw'
    end
  end

  context "query_round_transactions" do
    it "OK" do
      now = Time.parse('2014-09-11 00:00:00+09:00')
      allow(Time).to receive(:now).and_return(now)

      RoundTransaction.create(:ref_trans_id=>'t2',:payout_amt=>10050,:win_amt=>-9000,:aasm_state=>'completed',:before_balance=>0,:after_balance=>10050,:trans_type=>'result',:property_id=>1000,:player_id=>100,:created_at=>'2014-09-09 12:10:00',:jc_jp_con_amt=>1234.567,:jc_jp_win_amt=>1234567,:pc_jp_con_amt=>123456,:pc_jp_win_amt=>123456789,:jp_win_id=>'winid',:jp_win_lev=>1,:jp_direct_pay=>1,:trans_date=>'2014-09-09 12:25:10',:round_id=>123,:external_game_id=>456,:total_bet_amt=>19050)
      RoundTransaction.create(:ref_trans_id=>'t3',:payout_amt=>10050,:win_amt=>-9000,:aasm_state=>'completed',:before_balance=>0,:after_balance=>10050,:trans_type=>'result',:property_id=>1000,:player_id=>100,:created_at=>'2014-09-09 12:10:00',:jc_jp_con_amt=>1234.567,:pc_jp_con_amt=>123456,:trans_date=>'2014-09-09 12:25:10',:round_id=>123,:external_game_id=>456,:total_bet_amt=>19050)
      ib = {:property_id=>1000,:from_time=>'2014-09-09 21:00:00',:to_time=>'2014-09-09 22:00:00'}
      ob = query_result_transactions(ib)
      expect(ob[:error_code]).to eq('OK')
      transactions = ob[:transactions]
      expect(transactions.length).to eq 2

      t2 = transactions.find {|t| t[:ref_trans_id]=='t2'}
      expect(t2[:status]).to eq 'completed'
      expect(t2[:win_amt]).to eq -90.0
      expect(t2[:payout_amt]).to eq 100.50
      expect(t2[:jp_direct_pay]).to eq true
      expect(t2[:jc_jp_con_amt]).to eq '1234.567'
      expect(t2[:jc_jp_win_amt]).to eq '1234567.0'
      expect(t2[:pc_jp_con_amt]).to eq '123456.0'
      expect(t2[:pc_jp_win_amt]).to eq '123456789.0'
      expect(t2[:jp_win_id]).to eq 'winid'
      expect(t2[:jp_win_lev]).to eq 1
      expect(t2[:bet_amt]).to eq 190.50
      expect(t2[:trans_date]).to eq '2014-09-09 21:10:00'

      t3 = transactions.find {|t| t[:ref_trans_id]=='t3'}
      expect(t3[:jc_jp_con_amt]).to eq '1234.567'
      expect(t3[:pc_jp_con_amt]).to eq '123456.0'
      expect(t3[:pc_jp_win_amt]).to eq nil
    end
  end

end
