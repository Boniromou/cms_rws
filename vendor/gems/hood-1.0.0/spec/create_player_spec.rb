require 'spec_helper'

include Hood

RSpec.describe Cashier, "create player" do
  include CashierSpecHelper

  before(:each) do
    clean_db
  end

  it "require parameter [:login_name,:currency]" do
    ib = {}
    ob = create_player(ib)
    expect(ob[:error_code]).to eq('MissingRequiredParameters')
    expect(ob[:message]).to include("login_name")
    expect(ob[:message]).to include("currency")
  end

  it "CurrencyNotSupport" do
    allow_any_instance_of(AmsService).to receive(:send_request).and_return({:error_code=>'CurrencyNotSupport'}.to_yaml)
    ib = {:property_id=>1,:login_name=>'ln',:currency=>'RMB',:shareholder=>'holder'}
    ob = create_player(ib)
    expect(ob[:error_code]).to eq('CurrencyNotSupport')
  end

  it "OK" do
    allow_any_instance_of(AmsService).to receive(:send_request).and_return({:error_code=>'OK',:id=>123,:login_name=>'ln',:currency=>'RMB',:currency_id=>2}.to_yaml)
    ib = {:property_id=>1,:login_name=>'ln',:currency=>'RMB',:shareholder=>'holder'}
    ob = create_player(ib)
    expect(ob[:error_code]).to eq('OK')
    p = Player[:property_id=>1,:login_name=>'ln']
    expect(p[:id]).to eq 123
    expect(p[:balance]).to eq 0
    expect(p[:shareholder]).to eq 'holder'
    expect(Currency[2][:name]).to eq 'RMB'
  end

  context "player already created" do
    before(:each) do
      Currency.dataset.insert(:id=>1,:name=>'RMB',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
      Property.dataset.insert(:id=>1000,:name=>'p',:secret_key=>'s',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
      Player.dataset.insert(:id=>123,:login_name=>'abc',:currency_id=>1,:property_id=>1000,:shareholder=>'holder',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    end

    it "AlreadyCreated" do
      ib = {:property_id=>1000,:login_name=>'abc',:currency=>'RMB',:shareholder=>'holder'}
      ob = create_player(ib)
      expect(ob[:error_code]).to eq('AlreadyCreated')
    end

    it "CurrencyNotMatch" do
      ib = {:property_id=>1000,:login_name=>'abc',:currency=>'HKD',:shareholder=>'holder'}
      ob = create_player(ib)
      expect(ob[:error_code]).to eq('CurrencyNotMatch')
    end

    it "VendorNotMatch" do
      ib = {:property_id=>1000,:login_name=>'abc',:currency=>'RMB',:shareholder=>'holder12'}
      ob = create_player(ib)
      expect(ob[:error_code]).to eq('VendorNotMatch')
    end

  end

end
