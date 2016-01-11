require 'spec_helper'

include Hood

RSpec.describe Cashier, "void_withdaw" do
  include CashierSpecHelper

  before(:each) do
    clean_db
    Currency.dataset.insert(:id=>1,:name=>'RMB',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Property.dataset.insert(:id=>1000,:name=>'p',:secret_key=>'k',:time_zone=>'+08:00',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Player.dataset.insert(:id=>123,:login_name=>'abc',:currency_id=>1,:property_id=>1000,:shareholder=>'holder',:balance=>20010,
                          :updated_at=>Time.now.utc,:lock_state=>'unlocked',:created_at=>Time.now.utc)
  end

  it "MissingRequiredParameters" do
    ib = {}
    ob = void_withdraw(ib)
    expect(ob[:error_code]).to eq('MissingRequiredParameters')
    expect(ob[:message]).to include("login_name")
    expect(ob[:message]).to include("ref_trans_id")
    expect(ob[:message]).to include("amt")
  end

  it "InvalidAmount" do
    ib = {:amt=>0,:login_name=>'abc',:ref_trans_id=>'T1'}
    ob = void_withdraw(ib)
    expect(ob[:error_code]).to eq('InvalidAmount')
  end

  it "VoidTransactionNotExist" do
    ib = {:amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    ob = void_withdraw(ib)
    expect(ob[:error_code]).to eq('VoidTransactionNotExist')
    t = VoidWithdrawTransaction[:ref_trans_id=>'T1']
    expect(t).to eq nil
  end

  it "OK" do
    ib = {:amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    withdraw(ib)
    ib = {:amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    ob = void_withdraw(ib)
    expect(ob[:error_code]).to eq('OK')
    expect(ob[:amt]).to eq 100.1
    expect(ob[:before_balance]).to eq 100
    expect(ob[:after_balance]).to eq 200.1
    p = Player[123]
    expect(p[:balance]).to eq 200.1*100
    t = VoidWithdrawTransaction[:ref_trans_id=>'T1']
    expect(t[:amt]).to eq 100.1*100
    expect(t[:aasm_state]).to eq 'completed'
    expect(t[:before_balance]).to eq 100*100
    expect(t[:after_balance]).to eq 200.1* 100
  end

  it "OK - AlreadyProcessed" do
    ib = {:amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    withdraw(ib)
    ib = {:amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    void_withdraw(ib)
    ib = {:amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    ob = void_withdraw(ib)
    expect(ob[:error_code]).to eq('AlreadyProcessed')
    p = Player[123]
    expect(p[:balance]).to eq 200.1*100
  end

  it "VoidTransactionNotMatch" do
    ib = {:amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    withdraw(ib)
    ib = {:amt=>100.11,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    ob = void_withdraw(ib)
    expect(ob[:error_code]).to eq('VoidTransactionNotMatch')
  end
end
