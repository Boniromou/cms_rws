require 'spec_helper'

include Hood

RSpec.describe Cashier, "create player" do
  include CashierSpecHelper

  before(:each) do
    clean_db
  end

  it "require parameter [:login_name, :currency, :player_id, :player_currency_id]" do
    ib = {}
    ob = create_internal_player(ib)
    expect(ob[:error_code]).to eq('MissingRequiredParameters')
    expect(ob[:message]).to include("login_name")
    expect(ob[:message]).to include("currency")
    expect(ob[:message]).to include("player_id")
    expect(ob[:message]).to include("player_currency_id")
  end

  it "OK" do
    ib = {:property_id=>1,:login_name=>'ln',:currency=>'RMB',:shareholder=>'holder', :player_id => 1, :player_currency_id => 1}
    ob = create_internal_player(ib)
    expect(ob[:error_code]).to eq('OK')
    p = Player[:property_id=>1,:login_name=>'ln']
    expect(p[:id]).to eq 1
    expect(p[:balance]).to eq 0
    expect(p[:currency_id]).to eq 1
    expect(p[:shareholder]).to eq 'holder'
    expect(Currency[1][:name]).to eq 'RMB'
  end

  context "player already created" do
    before(:each) do
      Currency.dataset.insert(:id=>1,:name=>'RMB',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
      Property.dataset.insert(:id=>1000,:name=>'p',:secret_key=>'s',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
      Player.dataset.insert(:id=>123,:login_name=>'abc',:currency_id=>1,:property_id=>1000,:shareholder=>'holder',:created_at=>Time.now.utc,:updated_at=>Time.now.utc)
    end

    it "AlreadyCreated" do
      ib = {:property_id=>1000,:login_name=>'abc',:currency=>'RMB',:shareholder=>'holder', :player_id => 123, :player_currency_id => 1}
      ob = create_player(ib)
      expect(ob[:error_code]).to eq('AlreadyCreated')
    end

    it "VendorNotMatch" do
      ib = {:property_id=>1000,:login_name=>'abc',:currency=>'RMB',:shareholder=>'holder12', :player_id => 123, :player_currency_id => 1}
      ob = create_player(ib)
      expect(ob[:error_code]).to eq('VendorNotMatch')
    end

  end

end
