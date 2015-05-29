require "feature_spec_helper"

describe PlayersController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
    @root_user = User.create!(:uid => 1, :employee_id => 'portal.admin')
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[8] Transaction History report' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      
      @player = Player.create!(:player_name => "test", :member_id => "123456", :card_id => "1234567890", :currency_id => 1,:balance => 0, :status => "active")
      @player2 = Player.create!(:player_name => "test2", :member_id => "123457", :card_id => "1234567891", :currency_id => 1,:balance => 100, :status => "active")
    end

    def create_player_transaction
      @player_transaction1 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "complete", :amount => 10000, :station_id => @station_id, :created_at => Time.now)
      @player_transaction2 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player2.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "complete", :amount => 20000, :station_id => @station_id, :created_at => Time.now + 30 * 60)
      @player_transaction3 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "complete", :amount => 30000, :station_id => @station_id, :created_at => Time.now + 60 * 60)
    end

    after(:each) do
      #PlayerTransaction.delete_all
    end

    xit '[8.1] successfully generate report. (search by card ID)' do
      login_as_admin
      create_player_transaction
      visit home_path
      click_link I18n.t("tree_panel.balance")
      fill_search_info("member_id", @player.member_id)

      find("#button_find").click
      check_balance_page

      within "div#content" do
        click_link I18n.t("tree_panel.player_transaction")
      end
      
      check_player_transaction_page
      expect(find("input#id_number").value).to eq @player.card_id

      find("input#search").click
      check_player_transaction_result_items([@player_transaction1, @player_transaction3])
    end

    it '[8.2] successfully generate report. (search by time)', js: true do
      login_as_admin
      create_player_transaction
      visit search_transactions_path
      check_player_transaction_page_js

      fill_in "datetimepicker_start_time", :with => (Time.now + 20 * 60)
      find("input#search").click
      wait_for_ajax

      check_player_transaction_result_items([@player_transaction2, @player_transaction3])
    end

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

    it '[8.6] Transaction history unauthorized' do
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["balance"])
      set_permission(@test_user,"cashier",:player_transaction,[])
      visit home_path
      click_link I18n.t("tree_panel.balance")
      fill_search_info("member_id", @player.member_id)
      find("#button_find").click

      check_balance_page
      check_player_info
      expect(page).to_not have_selector("div a#player_transaction")
    end
    
    it '[8.7] re-print slip', :js => true do
      login_as_admin
      create_player_transaction
      visit search_transactions_path
      check_player_transaction_page_js
      fill_search_info_js("member_id", @player2.member_id)
      find("input#search").click
      
      find("div input#reprint").click
      wait_for_ajax
      expect(page.driver.browser.window_handles.length).to eq 1
    end
    
    it '[8.9] Re-print slip unauthorized', js: true do
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player_transaction,["search"])
      create_player_transaction
      visit search_transactions_path
      check_player_transaction_page_js

      fill_in "datetimepicker_start_time", :with => (Time.now + 20 * 60)
      find("input#search").click
      wait_for_ajax

      check_player_transaction_result_items([@player_transaction2,@player_transaction3], false)
    end
    
    it '[8.10] empty search', :js => true do
      login_as_admin
      create_player_transaction
      visit search_transactions_path
      check_player_transaction_page_js
      fill_in "datetimepicker_start_time", :with => "abc"
      find("input#search").click
      wait_for_ajax
      check_player_transaction_result_items([@player_transaction1,@player_transaction2,@player_transaction3])
      expect(find("input#datetimepicker_start_time").value).to eq Time.parse(Time.now.strftime("%d")).getlocal.strftime("%Y-%m-%d %H:%M:%S")
    end
  end
end
