require 'rails_helper'

describe PlayersController do
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

  describe 'Query Balance' do
    before(:each) do
      clean_dbs
      @player = Player.create!(:player_name => "exist", :member_id => 123456, :card_id => 1234567890, :currency_id => 1, :balance => 9999, :status => "active")
      controller.class.skip_before_filter :check_session_expiration, :authenticate_user!
      allow_any_instance_of(ApplicationController).to receive(:permission_granted?).and_return(true)
      bypass_rescue
    end

    after(:each) do
      clean_dbs
    end

    it 'should be able to query balance' do
      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(99.99)

      expect{ get 'balance', {member_id: 123456} }.to_not raise_error
    end

    it 'should raise error when not match' do
      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(0.0)

      expect{ get 'balance', {member_id: 123456} }.to raise_error(BalanceNotMatch)
    end
  end
end
