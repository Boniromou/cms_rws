require "feature_spec_helper"
require "rails_helper"

describe PlayerInfosController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[29] Itegration Service Cage APIs Login' do
    before(:each) do
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 2, :status => "active", :licensee_id => 20000)
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
      @patron_result = {:error_code => 'OK', :player => {:blacklist => false, :member_id => '123456', :card_id => '1234567890', :pin_status => 'used', :licensee_id => 20000, :test_mode_player => false, :deactivated => false}}
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return(Requester::PlayerInfoResponse.new(@patron_result))
      bypass_rescue
    end

    it '[29.1] Credential is not exist' do
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_raise(Request::InvalidCardId)
      allow_any_instance_of(Requester::Station).to receive(:validate_machine_token).and_return(Requester::StationResponse.new({:error_code => 'OK'}))
      post 'retrieve_player_info', {:credential => "1234567891", :machine_token => "1234567891", :pin => "1234"}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidCardId'
    end

    it '[29.2] Card ID is exist and generate token' do
      mock_token = "afe1f247-5eaa-4c2c-91c7-33a5fb637713"
      allow_any_instance_of(Requester::Station).to receive(:validate_machine_token).and_return(Requester::StationResponse.new({:error_code => 'OK'}))
      wallet_response = Requester::GetPlayerBalanceResponse.new({:error_code => 'OK', :balance => 100.00, :credit_balance => 99.99, :credit_expired_at => @credit_expird_at})
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(wallet_response)
      allow_any_instance_of(Requester::Patron).to receive(:validate_pin).and_return(Requester::ValidatePinResponse.new({:error_code => 'OK'}))
      allow(SecureRandom).to receive(:uuid).and_return(mock_token)
      post 'retrieve_player_info', {:credential => "1234567890", :machine_type => 'game_terminal', :machine_token => "1234567891", :pin => "1234", :property_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
      expect(result[:session_token]).to eq mock_token
      expect(result[:login_name]).to eq @player.member_id
      expect(result[:currency]).to eq Currency.find(@player.currency_id).name
      expect(result[:balance]).to eq 100.0
      expect(result[:test_mode_player]).to eq false
    end

    it '[29.3] Player is locked' do
      @player.lock_account!
      allow_any_instance_of(Requester::Station).to receive(:validate_machine_token).and_return(Requester::StationResponse.new({:error_code => 'OK'}))
      get 'retrieve_player_info', {:credential => "1234567890", :machine_type => 'game_terminal', :machine_token => "1234567891", :pin => "1234", :property_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'PlayerLocked'
    end

    it '[29.4] Validate PIN fail' do
      mock_token = "afe1f247-5eaa-4c2c-91c7-33a5fb637713"
      allow_any_instance_of(Requester::Station).to receive(:validate_machine_token).and_return(Requester::StationResponse.new({:error_code => 'OK'}))
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return({:balance => 100.00, :credit_balance => 99.99, :credit_expired_at => @credit_expird_at})
      allow_any_instance_of(Requester::Patron).to receive(:validate_pin).and_raise(Remote::PinError)
      get 'retrieve_player_info', {:credential => "1234567890", :machine_type => 'game_terminal', :machine_token => "1234567891", :pin => "1234", :property_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidPin'
    end
  end

  describe '[41] get player Currency API ' do
    before(:each) do
      bypass_rescue
      @player = Player.create!(:id => 10, :first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 2, :status => "active", :licensee_id => 20000)
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
    end

    it '[41.1] Return Currency' do
      get 'get_player_currency', {:login_name => @player.member_id, licensee_id: 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
      expect(result[:currency]).to eq 'HKD'
    end

    it '[41.2] Return Currency fail' do
      get 'get_player_currency', {:login_name => '1234', licensee_id: 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidLoginName'
    end
  end

  describe '[74] test mode player API ' do
    before(:each) do
      bypass_rescue
      @player = Player.create!(:id => 10, :first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 2, :status => "active", :licensee_id => 20000, :test_mode_player => true)
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
    end

    it '[74.1] Get is test mode player success' do
      @token = Token.create!(:session_token => 'abm39492i9jd9wjn', :player_id => 10, :expired_at => Time.now + 1800)
      get 'is_test_mode_player', {:login_name => @player.member_id, :session_token => @token.session_token, licensee_id: 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
      expect(result[:test_mode_player]).to eq true
    end

    it '[74.2] Get is test mode player fail with invalid token' do
      get 'is_test_mode_player', {:login_name => @player.member_id, :session_token => 'abc', licensee_id: 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidSessionToken'
      expect(result[:error_msg]).to eq 'Session token is invalid.'
      expect(result[:test_mode_player]).to eq nil
    end
  end
end
