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
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => 123456, :card_id => 1234567890, :currency_id => 2, :status => "active", :property_id => 20000)
      controller.class.skip_before_filter :check_session_expiration, :authenticate_user!
      allow_any_instance_of(ApplicationController).to receive(:authorize_action).and_return(true)
      bypass_rescue
    end

    after(:each) do
      clean_dbs
    end

    it 'should be able to query balance' do
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return({:balance => 99.99, :credit_balance => 0.0})
      allow_any_instance_of(ApplicationPolicy::Scope).to receive(:resolve).and_return(Player.where(:property_id => 20000))
      
      expect{ get 'balance', {member_id: 123456} }.to_not raise_error
    end
  end
end
