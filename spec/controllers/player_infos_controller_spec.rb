require "feature_spec_helper"
require "rails_helper"

describe PlayerInfosController do
  def clean_dbs
    Token.delete_all
    PlayersLockType.delete_all
    PlayerTransaction.delete_all
    Player.delete_all
    ChangeHistory.delete_all
  end

  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[29] Itegration Service Cage APIs Login' do
    before(:each) do
      clean_dbs
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active", :property_id => 20000)
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
      bypass_rescue
    end

    after(:each) do
      clean_dbs
    end

    it '[29.1] Card ID is not exist' do
      allow_any_instance_of(Requester::Station).to receive(:validate_machine_token).and_return({:error_code => 'OK'})
      post 'retrieve_player_info', {:card_id => "1234567891", :machine_token => "1234567891", :pin => "1234"}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidCardId'
    end

    it '[29.2] Card ID is exist and generate token' do
      mock_token = "afe1f247-5eaa-4c2c-91c7-33a5fb637713"
      allow_any_instance_of(Requester::Station).to receive(:validate_machine_token).and_return({:error_code => 'OK'})
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return({:balance => 100.00, :credit_balance => 99.99, :credit_expired_at => @credit_expird_at})
      allow_any_instance_of(Requester::Patron).to receive(:validate_pin).and_return({})
      allow(SecureRandom).to receive(:uuid).and_return(mock_token)
      post 'retrieve_player_info', {:card_id => "1234567890", :machine_type => 'game_terminal', :machine_token => "1234567891", :pin => "1234", :property_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
      expect(result[:session_token]).to eq mock_token
      expect(result[:login_name]).to eq @player.member_id
      expect(result[:currency]).to eq Currency.find(@player.currency_id).name
      expect(result[:balance]).to eq 100.0
    end

    it '[29.3] Player is locked' do
      @player.lock_account!
      allow_any_instance_of(Requester::Station).to receive(:validate_machine_token).and_return({:error_code => 'OK'})
      get 'retrieve_player_info', {:card_id => "1234567890", :machine_type => 'game_terminal', :machine_token => "1234567891", :pin => "1234", :property_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'PlayerLocked'
    end

    it '[29.4] Validate PIN fail' do
      mock_token = "afe1f247-5eaa-4c2c-91c7-33a5fb637713"
      allow_any_instance_of(Requester::Station).to receive(:validate_machine_token).and_return({:error_code => 'OK'})
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return({:balance => 100.00, :credit_balance => 99.99, :credit_expired_at => @credit_expird_at})
      allow_any_instance_of(Requester::Patron).to receive(:validate_pin).and_raise(Remote::PinError)
      get 'retrieve_player_info', {:card_id => "1234567890", :machine_type => 'game_terminal', :machine_token => "1234567891", :pin => "1234", :property_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidPin'
    end
  end

  describe '[41] get player Currency API ' do
    before(:each) do
      clean_dbs
      bypass_rescue
      @player = Player.create!(:id => 10, :first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active", :property_id => 20000)
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
    end

    after(:each) do
      Player.delete_all
      clean_dbs
    end

    it '[41.1] Return Currency' do
      get 'get_player_currency', {:login_name => @player.member_id}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
      expect(result[:currency]).to eq 'HKD'
    end

    it '[41.2] Return Currency fail' do
      get 'get_player_currency', {:login_name => '1234'}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidLoginName'
    end
  end

  describe '[63] Lock Player API' do
    before(:each) do
      clean_dbs
      bypass_rescue
      @player = Player.create!(:id => 10, :first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active", :property_id => 20000)
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
    end

    after(:each) do
      PlayersLockType.delete_all
      Player.delete_all
      clean_dbs
    end

    it '[63.1] Lock player success' do
      post 'lock_player', {:login_name => @player.member_id}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
      @player.reload
      expect(@player.status).to eq 'locked'
      expect(@player.has_lock_type?('cage_lock')).to eq true

      ch = ChangeHistory.first
      expect(ch.action_by).to eq 'system'
      expect(ch.object).to eq 'player'
      expect(ch.action).to eq 'lock'
      expect(ch.change_detail).to eq "Member ID: #{@player.member_id}"
      expect(ch.property_id).to eq @player.property_id

    end

    it '[63.2] Player not found' do
      post 'lock_player', {:login_name => 'not_exist'}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidLoginName'
      expect(result[:error_msg]).to eq 'Login name is invalid.'
      @player.reload
      expect(@player.status).to eq 'active'
      expect(@player.has_lock_type?('cage_lock')).to eq false
    end
  end
end
