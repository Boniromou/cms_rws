require "feature_spec_helper"
require "rails_helper"

describe KioskController do
  def clean_dbs
    Token.delete_all
    PlayersLockType.delete_all
    PlayerTransaction.delete_all
    KioskTransaction.delete_all
    Player.delete_all
  end

  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[76] Login Kiosk API' do
    before(:each) do
      clean_dbs
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 2, :status => "active", :licensee_id => 20000)
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
      bypass_rescue
    end

    after(:each) do
      clean_dbs
    end

    it '[76.1] Card ID is exist and generate token' do
      mock_token = "afe1f247-5eaa-4c2c-91c7-33a5fb637713"
      wallet_response = Requester::GetPlayerBalanceResponse.new({:error_code => 'OK', :balance => 100.00, :credit_balance => 99.99, :credit_expired_at => @credit_expird_at})
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(wallet_response)
      allow_any_instance_of(Requester::Patron).to receive(:validate_pin).and_return(Requester::ValidatePinResponse.new({:error_code => 'OK'}))
      allow(SecureRandom).to receive(:uuid).and_return(mock_token)
      post 'kiosk_login', {:card_id => "1234567890", :kiosk_id => "1234567891", :pin => "1234", :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
      expect(result[:session_token]).to eq mock_token
      expect(result[:login_name]).to eq @player.member_id
      expect(result[:currency]).to eq Currency.find(@player.currency_id).name
      expect(result[:balance]).to eq 100.0
    end

    it '[76.2] Card ID is not exist' do
      post 'kiosk_login', {:card_id => "1234567891", :kiosk_id => "1234567891", :pin => "1234", :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidCardId'
    end

    it '[76.3] Player is locked' do
      @player.lock_account!
      get 'kiosk_login', {:card_id => "1234567890", :kiosk_id => "1234567890", :pin => "1234", :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'PlayerLocked'
    end

    it '[76.4] Validate PIN fail' do
      allow_any_instance_of(Requester::Patron).to receive(:validate_pin).and_raise(Remote::PinError)
      get 'kiosk_login', {:card_id => "1234567890", :kiosk_id => "1234567890", :pin => "1234", :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidPin'
    end

    it '[76.5] Retrieve Balance fail' do
      allow_any_instance_of(Requester::Patron).to receive(:validate_pin).and_return(Requester::ValidatePinResponse.new({:error_code => 'OK'}))
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(Requester::NoBalanceResponse.new)
      get 'kiosk_login', {:card_id => "1234567890", :kiosk_id => "1234567890", :pin => "1234", :casino_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'RetrieveBalanceFail'
    end
  end
end
