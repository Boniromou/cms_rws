require 'spec_helper'

include Hood

RSpec.describe Cashier, "credit_auto_expire" do
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
    ob = credit_auto_expire(ib)
    expect(ob[:error_code]).to eq('MissingRequiredParameters')
    expect(ob[:message]).to include("login_name")
  end

  it "CreditNotYetExpired" do
    ib = {:login_name=>'abc',:property_id=>1000}
    ob = credit_auto_expire(ib)
    expect(ob[:error_code]).to eq('CreditNotYetExpired')
    t = CreditAutoExpireTransaction.first
    expect(t).to be_nil
  end

  it "OK" do
    t = Time.now
    Player[123].update({:credit_expired_at=>t-1})
    old_expired_at = Player[123][:credit_expired_at]
    ib = {:login_name=>'abc',:property_id=>1000}
    ob = credit_auto_expire(ib)
    expect(ob[:error_code]).to eq('OK')
    expect(ob[:credit_amt]).to eq 200.1
    expect(ob[:credit_before_balance]).to eq 200.1
    expect(ob[:credit_after_balance]).to eq 0
    expect(ob[:before_balance]).to eq 1.0
    expect(ob[:after_balance]).to eq 1.0
    p = Player[123]
    expect(p[:balance]).to eq 100
    expect(p[:credit_expired_at]).to eq old_expired_at
    t = CreditExpireTransaction.first
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
