require 'spec_helper'

include Hood

RSpec.describe Cashier, "credit_expire" do
  include CashierSpecHelper

  before(:each) do
    clean_db
    Currency.dataset.insert(:id=>1,:name=>'RMB',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    Property.dataset.insert(:id=>1000,:time_zone=>'+08:00',:secret_key=>'k',:name=>'p',:created_at=>Time.now.utc,:updated_at=>Time.now.utc,:credit_mode=>'partial')
    Player.dataset.insert(:id=>123,:login_name=>'abc',:currency_id=>1,:property_id=>1000,:shareholder=>'holder',:balance=>100,
      :credit_balance=>20010,:credit_expired_at=>'2999-10-10 00:00:00',:updated_at=>Time.now.utc,:lock_state=>'unlocked',:created_at=>Time.now.utc)
  end

  it "MissingRequiredParameters" do
    ib = {}
    ob = credit_expire(ib)
    expect(ob[:error_code]).to eq('MissingRequiredParameters')
    expect(ob[:message]).to include("login_name")
    expect(ob[:message]).to include("ref_trans_id")
    expect(ob[:message]).to include("credit_amt")
  end

  it "InvalidAmount" do
    ib = {:credit_amt=>0,:login_name=>'abc',:ref_trans_id=>'T1'}
    ob = credit_expire(ib)
    expect(ob[:error_code]).to eq('InvalidAmount')
  end

  it "AmountNotMatch" do
    ib = {:credit_amt=>200.0,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    ob = credit_expire(ib)
    expect(ob[:error_code]).to eq('AmountNotMatch')
    expect(ob[:balance]).to eq 1.0
    expect(ob[:credit_balance]).to eq 200.1
    t = CreditExpireTransaction[:ref_trans_id=>'T1']
    expect(t).to be_nil
  end

  it "OK" do
    ib = {:credit_amt=>200.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
    ob = credit_expire(ib)
    expect(ob[:error_code]).to eq('OK')
    expect(ob[:credit_amt]).to eq 200.1
    expect(ob[:credit_before_balance]).to eq 200.1
    expect(ob[:credit_after_balance]).to eq 0
    expect(ob[:before_balance]).to eq 1.0
    expect(ob[:after_balance]).to eq 1.0
    p = Player[123]
    expect(p[:balance]).to eq 100
    expect(p[:credit_expired_at]).to be < Time.now
    t = CreditExpireTransaction[:ref_trans_id=>'T1']
    expect(t[:credit_amt]).to eq 200.1*100
    expect(t[:aasm_state]).to eq 'completed'
  end

  context "ref_trans_id exist" do
    before(:each) do
      ib = {:credit_amt=>200.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
      credit_expire(ib)
    end

    it "ALreadyProcessed" do
      ib = {:credit_amt=>200.1,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
      credit_expire(ib)
    end

    it "DuplicateTrans" do
      ib = {:credit_amt=>200.0,:login_name=>'abc',:property_id=>1000,:ref_trans_id=>'T1'}
      credit_expire(ib)
    end

  end

end
