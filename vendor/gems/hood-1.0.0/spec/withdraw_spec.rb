require 'spec_helper'

include Hood

RSpec.describe Cashier, "withdraw" do
  include CashierSpecHelper

  before(:each) do
    clean_db
    Currency.dataset.insert(:id=>1,:name=>'RMB',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Property.dataset.insert(:id=>1000,:time_zone=>'+08:00',:secret_key=>'k',:name=>'p',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Player.dataset.insert(:id=>123,:login_name=>'abc',:currency_id=>1,:property_id=>1000,:shareholder=>'holder',:balance=>20010,
                          :updated_at=>Time.now.utc,:lock_state=>'unlocked',:created_at=>Time.now.utc)
  end

  it "MissingRequiredParameters" do
    ib = {:trans_date=>''}
    ob = withdraw(ib)
    expect(ob[:error_code]).to eq('MissingRequiredParameters')
    expect(ob[:message]).to include("login_name")
    expect(ob[:message]).to include("ref_trans_id")
    expect(ob[:message]).to include("amt")
    expect(ob[:message]).to include("trans_date")
  end

  it "InvalidAmount" do
    ib = {:amt=>0,:login_name=>'abc',:ref_trans_id=>'T1'}
    ob = withdraw(ib)
    expect(ob[:error_code]).to eq('InvalidAmount')
  end

  it "AmountNotEnough" do
    ib = {:amt=>200.12,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    ob = withdraw(ib)
    expect(ob[:error_code]).to eq('AmountNotEnough')
    expect(ob[:balance]).to eq 200.1
    t = WithdrawTransaction[:ref_trans_id=>'T1']
    expect(t).to be_nil
  end

  it "OK" do
    ib = {:amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    ob = withdraw(ib)
    expect(ob[:error_code]).to eq('OK')
    expect(ob[:amt]).to eq 100.1
    expect(ob[:before_balance]).to eq 200.1
    expect(ob[:after_balance]).to eq 100
    p = Player[123]
    expect(p[:balance]).to eq 100*100
    t = WithdrawTransaction[:ref_trans_id=>'T1']
    expect(t[:amt]).to eq 100.1*100
    expect(t[:aasm_state]).to eq 'completed'
  end

  context "ref_trans_id exist" do
    before(:each) do
      ib = {:amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
      withdraw(ib)
    end

    it "ALreadyProcessed" do
      ib = {:amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
      withdraw(ib)
    end

    it "DuplicateTrans" do
      ib = {:amt=>100.2,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
      withdraw(ib)
    end

  end

end
