require "feature_spec_helper"
require "rails_helper"

describe TokensController do
  def clean_dbs
    Token.delete_all
    PlayersLockType.delete_all
    PlayerTransaction.delete_all
    Player.delete_all    
  end

  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end
  describe '[30] Cage API: Validate Token' do
    before(:each) do
      clean_dbs
      bypass_rescue
      @player = Player.create!(:id => 10, :first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active", :property_id => 20000)
      @token = Token.create!(:session_token => 'abm39492i9jd9wjn', :player_id => 10, :expired_at => Time.now + 1800)
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
    end

    after(:each) do
      Token.delete_all
      Player.delete_all
      clean_dbs
    end

    it '[30.1] Validation pass' do
      get 'validate', {:login_name => "123456", :session_token => 'abm39492i9jd9wjn', :property_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
    end

    it '[30.2] Validation fail with invalid token OK' do
      get 'validate', {:login_name => "123456", :session_token => 'a456456887676esn', :property_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidSessionToken'
      expect(result[:error_msg]).to eq 'Session token is invalid.'
    end
  end

  describe '[32] Cage API: Discard Token' do
    before(:each) do
      clean_dbs
      bypass_rescue
      @player = Player.create!(:id => 10, :first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active", :property_id => 20000)
      @token = Token.create!(:session_token => 'abm39492i9jd9wjn', :player_id => 10, :expired_at => Time.now.utc + 1800)
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
    end

    after(:each) do
      Token.delete_all
      Player.delete_all
      clean_dbs
    end

    it '[32.1] Logout success' do
      get 'discard', {:session_token => 'abm39492i9jd9wjn', :login_name => '123456', :property_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
      token_test = Token.find_by_session_token('abm39492i9jd9wjn')
      token_test.expired_at.strftime("%Y-%m-%d %H:%M:%S UTC").should == (Time.now.utc - 100).strftime("%Y-%m-%d %H:%M:%S UTC")
    end

    it '[32.2] Logout fail' do
      get 'discard', {:session_token => 'abm394929wjn', :login_name => '123456', :property_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidSessionToken'
      expect(result[:error_msg]).to eq 'Session token is invalid.'
    end
  end

  describe '[33] Cage API: Keep Alive' do
    before(:each) do
      clean_dbs
      bypass_rescue
      @player = Player.create!(:id => 10, :first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active", :property_id => 20000)
      @token = Token.create!(:session_token => 'abm39492i9jd9wjn', :player_id => 10, :expired_at => Time.now + 1800)
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
    end

    after(:each) do
      Token.delete_all
      Player.delete_all
      clean_dbs
    end

    it '[33.1] Keep alive success' do
      post 'keep_alive', {:session_token => 'abm39492i9jd9wjn', :login_name => '123456', :property_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
      @token.expired_at.strftime("%Y-%m-%d %H:%M:%S UTC").should == (Time.now.utc + 1800).strftime("%Y-%m-%d %H:%M:%S UTC")
    end

    it '[33.2] Keep alive fail with wrong token' do
      post 'keep_alive', {:session_token => 'abm394jd9wjn', :login_name => '123456', :property_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidSessionToken'
      expect(result[:error_msg]).to eq 'Session token is invalid.'
    end

    it '[33.3] Keep alive timeout' do
      @token2 = Token.create!(:session_token => 'abm39492i', :player_id => 10, :expired_at => Time.now - 1800)
      post 'keep_alive', {:session_token => 'abm39492i', :login_name => '123456', :property_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidSessionToken'
      expect(result[:error_msg]).to eq 'Session token is invalid.'
    end
  end
end
