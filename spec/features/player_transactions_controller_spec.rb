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

  describe '[8] Transaction History report' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      mock_patron_not_change
      
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => "123456", :card_id => "1234567890", :currency_id => 1, :status => "active")
      @player2 = Player.create!(:first_name => "test", :last_name => "player2", :member_id => "123457", :card_id => "1234567891", :currency_id => 1, :status => "active")

      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0.0)
    end

    def create_player_transaction
      @location6 = Location.create!(:name => "LOCATION6", :status => "active")
      @station6 = Station.create!(:name => "STATION6", :status => "active", :location_id => @location6.id)
      @player_transaction1 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 10000, :station_id => @station6.id, :created_at => Time.now)
      @player_transaction2 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player2.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 20000, :station_id => @station6.id, :created_at => Time.now + 30 * 60)
      @player_transaction3 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 30000, :station_id => @station6.id, :created_at => Time.now + 60 * 60)
    end

    after(:each) do
      PlayerTransaction.delete_all
      Station.delete_all
      Location.delete_all
    end

    # xit '[8.1] successfully generate report. (search by card ID)' do
    #   login_as_admin
    #   create_player_transaction
    #   visit home_path
    #   click_link I18n.t("tree_panel.balance")
    #   fill_search_info("member_id", @player.member_id)

    #   find("#button_find").click
    #   check_balance_page

    #   within "div#content" do
    #     click_link I18n.t("tree_panel.player_transaction")
    #   end
      
    #   check_player_transaction_page
    #   expect(find("input#id_number").value).to eq @player.card_id

    #   find("input#search").click
    #   check_player_transaction_result_items([@player_transaction1, @player_transaction3])
    # end

    # it '[8.2] successfully generate report. (search by time)', js: true do
    #   login_as_admin
    #   create_player_transaction
    #   visit search_transactions_path
    #   check_player_transaction_page_js

    #   fill_in "datetimepicker_start_time", :with => (Time.now + 20 * 60)
    #   find("input#search").click
    #   wait_for_ajax

    #   check_player_transaction_result_items([@player_transaction2, @player_transaction3])
    # end

    it '[8.3] successfully generate report. (search by transaction ID)', js: true do
      login_as_admin
      create_player_transaction
      visit search_transactions_path 
      check_player_transaction_page_js

      fill_in "transaction_id", :with => @player_transaction3.id
      find("input#selected_tab_index").set "1"

      find("input#search").click
      wait_for_ajax
      check_player_transaction_result_items([@player_transaction3])
    end

    it '[8.4] Transaction not found' do
      login_as_admin
      visit search_transactions_path
      check_player_transaction_page
      fill_search_info("member_id", "12345678")
      find("input#search").click

      expect(find("div.widget-body label").text).to eq t("report_search.no_transaction_found")
    end
    
    it '[8.5] successfully generate report. (search by member ID)', js: true do
      login_as_admin
      create_player_transaction
      visit search_transactions_path
      check_player_transaction_page_js

      fill_search_info_js("member_id", @player2.member_id)
      find("input#search").click
      wait_for_ajax

      check_player_transaction_result_items([@player_transaction2])
    end

    it '[8.6] Transaction history unauthorized', :js => true do
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["balance"])
      set_permission(@test_user,"cashier",:player_transaction,[])
      expect(page).to_not have_selector("li#nav_search_transactions")
    end
    
    it '[8.7] re-print slip', :js => true do
      login_as_admin
      create_player_transaction
      visit search_transactions_path
      check_player_transaction_page_js
      fill_search_info_js("member_id", @player2.member_id)
      find("input#search").click
      
      find("div a#reprint").click
      wait_for_ajax
      expect(page.source).to have_selector("iframe")
    end
    
    it '[8.9] Re-print slip unauthorized', js: true do
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player_transaction,["search"])
      create_player_transaction
      visit search_transactions_path
      check_player_transaction_page_js
      fill_search_info_js("member_id", @player.member_id)
      find("input#search").click
      wait_for_ajax

      check_player_transaction_result_items([@player_transaction1, @player_transaction3], false,false,false)
    end
    
    # it '[8.10] empty search', :js => true do
    #   login_as_admin
    #   create_player_transaction
    #   visit search_transactions_path
    #   check_player_transaction_page_js
    #   fill_in "datetimepicker_start_time", :with => "abc"
    #   find("input#search").click
    #   wait_for_ajax
    #   check_flash_message I18n.t("report_search.datetime_format_not_valid")
    #   expect(page).to_not have_selector("div#wid-id-2")
    #   # expect(find("input#datetimepicker_start_time").value).to eq Time.parse(Time.now.strftime("%d")).getlocal.strftime("%Y-%m-%d %H:%M:%S")
    # end

    it '[8.11] search data out of range', js: true do
      login_as_admin
      create_player_transaction
      visit search_transactions_path
      check_player_transaction_page_js

      fill_in "start", :with => (@accounting_date)
      fill_in "end", :with => ("2015-08-15")
      fill_search_info_js("member_id", @player2.member_id)
      find("input#search").click
      wait_for_ajax

      check_flash_message I18n.t("report_search.limit_remark")
      expect(page).to_not have_selector("div#wid-id-2")
    end

    it '[8.12] search data incorrect time period', js: true do
      login_as_admin
      visit home_path
      visit search_transactions_path
      create_player_transaction
      check_player_transaction_page_js
      fill_in "start", :with => ("2015-09-01")
      fill_in "end", :with => ("2015-08-15")
      find("input#search").click
      expect(find("input#start").value).to eq "2015-08-15"
    end

    it '[8.13] show error message when empty card ID/membership ID', js: true do
      login_as_admin
      visit home_path
      visit search_transactions_path
      create_player_transaction
      check_player_transaction_page_js
      fill_in "start", :with => ("2015-09-01")
      fill_in "end", :with => ("2015-09-30")
      find("input#search").click
      wait_for_ajax

      check_flash_message I18n.t("transaction_history.no_id")
      expect(page).to_not have_selector("div#wid-id-2")
    end
  end
  
  describe '[16] Print Transaction report' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      mock_patron_not_change
      
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => "123456", :card_id => "1234567890", :currency_id => 1, :status => "active")
      @player2 = Player.create!(:first_name => "test", :last_name => "player2", :member_id => "123457", :card_id => "1234567891", :currency_id => 1, :status => "active")

      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0.0)
    end

    def create_player_transaction
      @location6 = Location.create!(:name => "LOCATION6", :status => "active")
      @station6 = Station.create!(:name => "STATION6", :status => "active", :location_id => @location6.id)
      @player_transaction1 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 10000, :station_id => @location6.id, :created_at => Time.now)
      @player_transaction2 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player2.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 20000, :station_id => @location6.id, :created_at => Time.now + 30 * 60)
      @player_transaction3 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 30000, :station_id => @location6.id, :created_at => Time.now + 60 * 60)
    end

    after(:each) do
      PlayerTransaction.delete_all
      Station.delete_all
      Location.delete_all
    end
    
    it '[16.2] unauthorized print transaction report', js: true do
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["balance"])
      set_permission(@test_user,"cashier",:player_transaction,["search"])
      create_player_transaction
      visit search_transactions_path
      check_player_transaction_page_js

      fill_search_info_js("member_id", @player2.member_id)
      find("input#search").click
      wait_for_ajax

      expect(page.source).to_not have_selector("button#print_player_transaction")
    end
  end
  
  describe '[49] Slip ID' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      mock_close_after_print
      mock_have_enable_station
      mock_patron_not_change
      reset_slip_number
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => "123456", :card_id => "1234567890", :currency_id => 1, :status => "active")

      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0.0)
      allow_any_instance_of(Requester::Wallet).to receive(:deposit).and_return('OK')
      allow_any_instance_of(Requester::Wallet).to receive(:withdraw).and_return('OK')
      allow_any_instance_of(Requester::Wallet).to receive(:void_deposit).and_return('OK')
      allow_any_instance_of(Requester::Wallet).to receive(:void_withdraw).and_return('OK')
    end
    
    after(:each) do
    end

    def create_player_transaction
      @location = Location.create!(:name => "LOCATION", :status => "active")
      @station = Station.create!(:name => "STATION", :status => "active", :location_id => @location.id)
      allow(Station).to receive(:find_by_terminal_id).and_return(@station)
      @player_transaction1 = do_deposit(1000)
      @player_transaction2 = do_deposit(1000)
      @void_transaction1 = do_void(@player_transaction1.id)
      @void_transaction2 = do_void(@player_transaction2.id)
      @player_transaction3 = do_deposit(5000)
      @void_transaction3 = do_void(@player_transaction3.id)
      @player_transaction4 = do_deposit(5000)
      @player_transaction5 = do_withdraw(5000)
      @void_transaction4 = do_void(@player_transaction5.id)
      @player_transaction6 = do_withdraw(5000)
    end
    
    it '[49.1] Show correct slip ID', :js => true do
      login_as_admin
      create_player_transaction
      visit search_transactions_path 
      check_player_transaction_page_js

      fill_in "start", :with => @player_transaction2.shift.accounting_date.to_s
      fill_in "end", :with => @player_transaction1.shift.accounting_date.to_s
      fill_in "id_number", :with => @player_transaction1.player.card_id
      find("input#selected_tab_index").set "0"

      find("input#search").click
      wait_for_ajax
      @player_transaction1.reload
      @player_transaction2.reload
      @player_transaction3.reload
      @player_transaction4.reload
      @player_transaction5.reload
      @player_transaction6.reload

      check_player_transaction_result_items([@player_transaction1,@player_transaction2,@player_transaction3,@player_transaction4,@player_transaction5,@player_transaction6])

      expect(@player_transaction1.slip_number).to eq 1
      expect(@player_transaction2.slip_number).to eq 2
      expect(@void_transaction1.slip_number).to eq 3
      expect(@void_transaction2.slip_number).to eq 4
      expect(@player_transaction3.slip_number).to eq 5
      expect(@void_transaction3.slip_number).to eq 6
      expect(@player_transaction4.slip_number).to eq 7
      expect(@player_transaction5.slip_number).to eq 1
      expect(@void_transaction4.slip_number).to eq 2
      expect(@player_transaction6.slip_number).to eq 3
    end
  end

  describe '[58] Update player info when search in transaction history' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => "123456", :card_id => "1234567890", :currency_id => 1, :status => "active")
      @player2 = Player.create!(:first_name => "test", :last_name => "player2", :member_id => "123457", :card_id => "1234567891", :currency_id => 1, :status => "active")

      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0.0)
    end

    after(:each) do
      clean_dbs
    end
    
    def create_player_transaction
      @location6 = Location.create!(:name => "LOCATION6", :status => "active")
      @station6 = Station.create!(:name => "STATION6", :status => "active", :location_id => @location6.id)
      @player_transaction1 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 10000, :station_id => @location6.id, :created_at => Time.now)
      @player_transaction2 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player2.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 20000, :station_id => @location6.id, :created_at => Time.now + 30 * 60)
      @player_transaction3 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 30000, :station_id => @location6.id, :created_at => Time.now + 60 * 60)
    end

    it '[58.1] Search transaction history with card change', :js => true do
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => 1234567893, :member_id => @player.member_id, :blacklist => @player.has_lock_type?('blacklist'), :pin_status => 'created'})
      login_as_admin
      create_player_transaction
      visit search_transactions_path 
      check_player_transaction_page_js

      fill_in "start", :with => @player_transaction2.shift.accounting_date.to_s
      fill_in "end", :with => @player_transaction1.shift.accounting_date.to_s
      fill_in "id_number", :with => @player_transaction1.player.card_id
      find("input#selected_tab_index").set "0"

      find("input#search").click
      wait_for_ajax
      p = Player.find(@player.id)
      expect(p.member_id).to eq @player.member_id
      expect(p.card_id).to eq '1234567893'
      expect(p.status).to eq @player.status
    end

    it '[58.2] Search transaction history with player not exist in cage' do
      @player.delete
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => 1234567893, :member_id => @player.member_id, :blacklist => @player.has_lock_type?('blacklist'), :pin_status => 'null'})
      login_as_admin
      visit search_transactions_path
      check_player_transaction_page
      fill_search_info("member_id", "12345678")
      find("input#search").click

      expect(find("div.widget-body label").text).to eq t("report_search.no_transaction_found")
    end
  end
end
