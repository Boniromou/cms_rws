require "feature_spec_helper"
require "rails_helper"

describe InternalRequestsController do
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
      @player = Player.create!(:id => 10, :first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 2, :status => "active", :licensee_id => 20000)
      @token = Token.create!(:session_token => 'abm39492i9jd9wjn', :player_id => 10, :expired_at => Time.now + 1800)
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
    end

    after(:each) do
      Token.delete_all
      Player.delete_all
      clean_dbs
    end

    it 'Internal validation pass' do
      get 'validate', {:login_name => "123456", :session_token => 'abm39492i9jd9wjn', :licensee_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
    end
  end

  describe '[63] Lock Player API' do
    before(:each) do
      clean_dbs
      bypass_rescue
      @player = Player.create!(:id => 10, :first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 2, :status => "active", :licensee_id => 20000)
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Parser).to receive(:verify).and_return([20000])
    end

    after(:each) do
      PlayersLockType.delete_all
      Player.delete_all
      clean_dbs
    end

    it '[63.1] Lock player success' do
      post 'lock_player', {:login_name => @player.member_id, :licensee_id => 20000, :property_id => 20000}
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
      expect(ch.licensee_id).to eq @player.licensee_id
      expect(ch.casino_id).to eq 20000

    end

    it '[63.2] Player not found' do
      post 'lock_player', {:login_name => 'not_exist', :licensee_id => 20000, :property_id => 20000}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidLoginName'
      expect(result[:error_msg]).to eq 'Login name is invalid.'
      @player.reload
      expect(@player.status).to eq 'active'
      expect(@player.has_lock_type?('cage_lock')).to eq false
    end
  end
end
