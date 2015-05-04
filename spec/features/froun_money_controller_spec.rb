require "feature_spec_helper"

describe FrontMoneyController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
    @root_user = User.create!(:uid => 1, :employee_id => 'portal.admin')
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[11] FM Activity Report' do
    before(:each) do
      clean_dbs
      create_shift_data
      
      @player = Player.create!(:player_name => "test", :member_id => "123456", :card_id => "1234567890", :currency_id => 1,:balance => 0, :status => "active")
      @player2 = Player.create!(:player_name => "test2", :member_id => "123457", :card_id => "1234567891", :currency_id => 1,:balance => 100, :status => "active")

      @station2 = Station.create!(:name => 'window#2')
    end

    def create_player_transaction
      @player_transaction1 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "complete", :amount => 10000, :station_id => @station_id, :created_at => Time.now)
      @player_transaction2 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player2.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "complete", :amount => 20000, :station_id => @station_id, :created_at => Time.now + 30*60)
      @player_transaction3 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "complete", :amount => 30000, :station_id => @station2.id, :created_at => Time.now + 60*60)
    end

    after(:each) do
      PlayerTransaction.delete_all
    end

    it '[11.1] Successfully generate FM Actiivty Report' do
      login_as_admin
      create_player_transaction
      visit search_front_money_path
      
      check_search_fm_page
      
      find("input#search").click
      transaction_hash = { @station_id => [@player_transaction1,@player_transaction2], @station2.id => [@player_transaction3] }
      check_fm_remort_result_items(transaction_hash)
    end

    it '[11.2] Search FM Activity Report Unauthorized' do
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:shift,[""])
      visit home_path
      first("aside#left-panel ul li#nav_front_money").should be_nil
    end

    it '[11.3] FM Activity Report not found' do
      login_as_admin
      visit search_front_money_path
      
      check_search_fm_page
      
      find("input#search").click
      expect(find("div.widget-body p").text).to eq "no result"
    end
      
  end
end
