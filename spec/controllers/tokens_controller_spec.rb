require 'rails_helper'

describe TokensController do
  def clean_dbs
    Player.delete_all    
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
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => '123456', :card_id => 1234567890, :currency_id => 1, :status => "active")
      bypass_rescue
    end

    after(:each) do
      clean_dbs
    end

    it '[29.1] Card ID is not exist' do
      get 'retrieve_player_info', {:card_id => "1234567891", :terminal_id => "1234567891", :pin => "1234"}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'InvalidCardId'
    end

    it '[29.2] Card ID is exist' do
      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(100.00)
      post 'retrieve_player_info', {:card_id => "1234567890", :terminal_id => "1234567891", :pin => "1234"}
      result = JSON.parse(response.body).symbolize_keys
      expect(result[:error_code]).to eq 'OK'
      expect(result[:error_msg]).to eq 'Request is carried out successfully.'
      #expect(result[:session_token]).to eq 'abc123'
      expect(result[:login_name]).to eq @player.member_id
      expect(result[:currency]).to eq Currency.find(@player.currency_id).name
      expect(result[:balance]).to eq 100.0
    end
  end
end
