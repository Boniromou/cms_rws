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
      
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => "123456", :card_id => "1234567890", :currency_id => 1, :status => "active")
      @player2 = Player.create!(:first_name => "test", :last_name => "player2", :member_id => "123457", :card_id => "1234567891", :currency_id => 1, :status => "active")

      @location6 = Location.create!(:name => "LOCATION6", :status => "active")
      @station6 = Station.create!(:name => "STATION6", :status => "active", :location_id => @location6.id)
      @station2 = Station.create!(:name => 'window#2', :status => "active", :location_id => @location6.id)
    end

    def create_player_transaction
      @player_transaction1 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 10000, :station_id => @station6.id, :created_at => Time.now)
      @player_transaction2 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player2.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 20000, :station_id => @station6.id, :created_at => Time.now + 30*60)
      @player_transaction3 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 30000, :station_id => @station2.id, :created_at => Time.now + 60*60)
    end

    after(:each) do
      PlayerTransaction.delete_all
      Station.delete_all
      Location.delete_all
    end

    it '[11.1] Successfully generate FM Actiivty Report', :js => true do
      login_as_admin
      create_player_transaction
      visit search_front_money_path
      
      check_search_fm_page
      
      find("input#search").click
      wait_for_ajax
      transaction_hash = { @station6.id => [@player_transaction1,@player_transaction2], @station2.id => [@player_transaction3] }
      check_fm_report_result_items(transaction_hash)
    end

    it '[11.2] Search FM Activity Report Unauthorized' do
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:shift,[""])
      visit home_path
      expect(first("aside#left-panel ul li#nav_front_money")).to be_nil
    end

    it '[11.3] FM Activity Report not found' do
      login_as_admin
      visit search_front_money_path
      
      check_search_fm_page
      
      find("input#search").click
      expect(find("div.widget-body label").text).to eq t("report_search.no_transaction_found")
    end
      
    it '[11.4] accounting date cannot be empty', :js => true do
      login_as_admin
      create_player_transaction
      visit search_front_money_path
      fill_in "accounting_date", :with => 1
      check_search_fm_page
      
      find("input#search").click
      wait_for_ajax
      transaction_hash = { @station6.id => [@player_transaction1,@player_transaction2], @station2.id => [@player_transaction3] }
      check_fm_report_result_items(transaction_hash)
      expect(find("input#accounting_date").value).to eq AccountingDate.current.accounting_date.strftime("%Y-%m-%d")
    end
  end
  
  describe '[17] Print FM Activity Report ' do
    before(:each) do
      clean_dbs
      create_shift_data
      
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => "123456", :card_id => "1234567890", :currency_id => 1, :status => "active")
      @player2 = Player.create!(:first_name => "test", :last_name => "player2", :member_id => "123457", :card_id => "1234567891", :currency_id => 1, :status => "active")

      @location6 = Location.create!(:name => "LOCATION6", :status => "active")
      @station6 = Station.create!(:name => "STATION6", :status => "active", :location_id => @location6.id)
      @station2 = Station.create!(:name => 'window#2', :status => "active", :location_id => @location6.id)
    end

    def create_player_transaction
      @player_transaction1 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 10000, :station_id => @station6.id, :created_at => Time.now)
      @player_transaction2 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player2.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 20000, :station_id => @station6.id, :created_at => Time.now + 30*60)
      @player_transaction3 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 30000, :station_id => @station2.id, :created_at => Time.now + 60*60)
    end

    after(:each) do
      PlayerTransaction.delete_all
      Station.delete_all
      Location.delete_all
    end

    it '[17.2] unauthorized print FM Activity report', :js => true do
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:shift,["search_fm"])
      create_player_transaction
      visit search_front_money_path
      
      check_search_fm_page
      
      find("input#search").click
      wait_for_ajax
      transaction_hash = { @station6.id => [@player_transaction1,@player_transaction2], @station2.id => [@player_transaction3] }
      check_fm_report_result_items(transaction_hash)
      
      expect(page.source).to_not have_selector("button#print_fm")
    end
  end
end
