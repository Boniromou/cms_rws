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

  describe 'token API' do
    before(:each) do
      clean_dbs
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => 123456, :card_id => 1234567890, :currency_id => 1, :status => "active")
      bypass_rescue
    end

    after(:each) do
      clean_dbs
    end

    it 'success retrieve player info' do
      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(100.00)
      get 'validate', {:card_id => "1234567890", :terminal_id => "1234567891", :pin => "1234"}
      result = response.body
      expect(result[:error_code]).to eq 'OK'
      expect(result[:message]).to eq 'Request is carried out successfully'
      expect(result[:session_token]).to eq 'abc123'
      expect(result[:login_name]).to eq @player.member_id
      expect(result[:curency]).to eq Currency.find(@player.currency_id)
      expect(result[:balance]).to eq "100.00"
    end
    
    it 'validate token' do
      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(100.00)
    end
  end
end
