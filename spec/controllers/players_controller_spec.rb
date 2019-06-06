require "feature_spec_helper"
require "rails_helper"

describe PlayersController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  describe 'Query Balance' do
    before(:each) do
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => 123456, :card_id => 1234567890, :currency_id => 2, :status => "active", :licensee_id => 20000)
      controller.class.skip_before_filter :check_session_expiration, :authenticate_user!
      allow_any_instance_of(ApplicationController).to receive(:authorize_action).and_return(true)
      allow_any_instance_of(ApplicationController).to receive(:current_casino_id).and_return(20000)
      bypass_rescue
    end

    it 'should be able to query balance' do
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(Requester::GetPlayerBalanceResponse.new({:balance => 99.99, :credit_balance => 0.0, :credit_expired_at => Time.now}))
      allow_any_instance_of(PlayerPolicy::Scope).to receive(:resolve).and_return(Player.where(:licensee_id => 20000))

      expect{ get 'balance', {member_id: 123456} }.to_not raise_error
    end
  end
end
