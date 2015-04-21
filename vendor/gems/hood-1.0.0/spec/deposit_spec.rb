require 'spec_helper'

include Hood

RSpec.describe Cashier, "deposit" do
  include CashierSpecHelper

  before(:each) do
    clean_db
    Currency.dataset.insert(:id=>1,:name=>'RMB',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Property.dataset.insert(:id=>1000,:name=>'p',:secret_key=>'k',:time_zone=>'+08:00',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Player.dataset.insert(:id=>123,:login_name=>'abc',:currency_id=>1,:property_id=>1000,:shareholder=>'holder',:balance=>0,
                          :updated_at=>Time.now.utc,:lock_state=>'unlocked',:created_at=>Time.now.utc)
  end

  it "MissingRequiredParameters" do
    ib = {:trans_date=>''}
    ob = deposit(ib)
    expect(ob[:error_code]).to eq('MissingRequiredParameters')
    expect(ob[:message]).to include("login_name")
    expect(ob[:message]).to include("ref_trans_id")
    expect(ob[:message]).to include("amt")
    expect(ob[:message]).to include("trans_date")
  end

  it "InvalidAmount" do
    ib = {:amt=>0,:login_name=>'abc',:ref_trans_id=>'T1'}
    ob = deposit(ib)
    expect(ob[:error_code]).to eq('InvalidAmount')
  end

  it "OK" do
    ib = {:amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    ob = deposit(ib)
    expect(ob[:error_code]).to eq('OK')
    expect(ob[:amt]).to eq 100.1
    expect(ob[:before_balance]).to eq 0
    expect(ob[:after_balance]).to eq 100.1
    p = Player[123]
    expect(p[:balance]).to eq 100.1*100
    t = DepositTransaction[:ref_trans_id=>'T1']
    expect(t[:amt]).to eq 100.1*100
    expect(t[:aasm_state]).to eq 'completed'
  end

  context "ref_trans_id exist" do
    before(:each) do
      ib = {:amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
      deposit(ib)
    end

    it "ALreadyProcessed" do
      ib = {:amt=>100.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
      deposit(ib)
    end

    it "DuplicateTrans" do
      ib = {:amt=>100.2,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
      deposit(ib)
    end

  end

end
