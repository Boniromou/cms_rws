require "feature_spec_helper"
require "rails_helper"

describe InternalTokensController do
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
end
