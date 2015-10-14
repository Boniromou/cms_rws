require "feature_spec_helper"
require "rails_helper"

describe TerminalsController do
  def clean_dbs
    Token.delete_all
    PlayersLockType.delete_all
    Player.delete_all    
  end

  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[39] Validate Terminal ID API' do
    before(:each) do
      clean_dbs
      bypass_rescue
    end

    after(:each) do
      clean_dbs
    end

    it '[39.1] Validate Terminal ID success' do
      get 'validate', {:terminal_id => "eb693ec8252cd630102fd0d0fb7c3485", :property_id => "20000"}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
      expect(result[:machine_name]).to eq 'abc1234'
    end

    it '[39.2] Validate Terminal ID fail' do
      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(100.00)
      get 'validate', {:terminal_id => "acbd123456", :property_id => "20000"}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidTerminalID'
      expect(result[:error_msg]).to eq 'Validate terminal id failed.'
    end
  end
end