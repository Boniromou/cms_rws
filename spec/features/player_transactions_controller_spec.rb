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
      
      @player = create_default_player
      @player2 = create_default_player(:last_name => "player2", :member_id => "123457", :card_id => "1234567891")

      mock_wallet_balance(0.0)
    end

    after(:each) do
      PlayerTransaction.delete_all
    end

    it '[8.2] successfully generate report. (search by accounting date)', js: true do
      login_as_admin
      create_player_transaction
      visit home_path
      click_link I18n.t("tree_panel.player_transaction")
      check_player_transaction_page_js

      fill_search_info_js("member_id", @player2.member_id)
      fill_in "start", :with => (Shift.last.accounting_date.strftime("%F"))
      fill_in "end", :with => (Shift.last.accounting_date.strftime("%F"))
      find("input#search").click
      wait_for_ajax

      check_player_transaction_result_items([@player_transaction2])
    end

    it '[8.3] successfully generate report. (search by slip ID)', js: true do
      login_as_admin
      create_player_transaction
      @player_transaction4 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 2, :status => "completed", :amount => 10000, :machine_token => @machine_token1, :created_at => Time.now, :slip_number => 1, :casino_id => 20000)
      visit home_path
      click_link I18n.t("tree_panel.player_transaction")
      check_player_transaction_page_js

      fill_in "slip_number", :with => @player_transaction1.slip_number
      find("input#selected_tab_index").set "1"

      find("input#search").click
      wait_for_ajax
      check_player_transaction_result_items([@player_transaction1,@player_transaction4])
    end

    it '[8.4] Transaction not found' do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.player_transaction")
      check_player_transaction_page
      fill_search_info("member_id", "12345678")
      find("input#search").click

      expect(find("div.widget-body label").text).to eq t("report_search.no_transaction_found")
    end
    
    it '[8.5] successfully generate report. (search by member ID)', js: true do
      login_as_admin
      create_player_transaction
      visit home_path
      click_link I18n.t("tree_panel.player_transaction")
      check_player_transaction_page_js

      fill_search_info_js("member_id", @player2.member_id)
      find("input#search").click
      wait_for_ajax

      check_player_transaction_result_items([@player_transaction2])
    end

    it '[8.6] Transaction history unauthorized', :js => true do
      login_as_test_user
      set_permission(@test_user,"cashier",:player,["balance"])
      set_permission(@test_user,"cashier",:player_transaction,[])
      expect(page).to_not have_selector("li#nav_search_transactions")
    end
    
    it '[8.7] re-print slip', :js => true do
      login_as_admin
      create_player_transaction
      visit home_path
      click_link I18n.t("tree_panel.player_transaction")
      check_player_transaction_page_js
      fill_search_info_js("member_id", @player2.member_id)
      find("input#search").click
      
      find("div a#reprint").click
      wait_for_ajax
      expect(page.source).to have_selector("iframe")
    end
    
    it '[8.9] Re-print slip unauthorized', js: true do
      login_as_test_user
      set_permission(@test_user,"cashier",:player_transaction,["search"])
      create_player_transaction
      visit home_path
      click_link I18n.t("tree_panel.player_transaction")
      check_player_transaction_page_js
      fill_search_info_js("member_id", @player.member_id)
      find("input#search").click
      wait_for_ajax

      check_player_transaction_result_items([@player_transaction1, @player_transaction3], false,false,false)
    end
    
    it '[8.10] empty search', :js => true do
      login_as_admin
      create_player_transaction
      visit home_path
      click_link I18n.t("tree_panel.player_transaction")
      check_player_transaction_page_js
      find("input#search").click
      wait_for_ajax
      check_flash_message I18n.t("transaction_history.no_id")
    end

    it '[8.11] search data out of range', js: true do
      login_as_admin
      create_player_transaction
      visit home_path
      click_link I18n.t("tree_panel.player_transaction")
      check_player_transaction_page_js

      fill_in "start", :with => (@accounting_date)
      fill_in "end", :with => ((Time.now + 4.month).strftime("%Y-%m-%d"))
      fill_search_info_js("member_id", @player2.member_id)
      find("input#search").click
      wait_for_ajax

      check_flash_message I18n.t("report_search.limit_remark",{day: ConfigHelper.new(@player.licensee_id).trans_history_search_range})
      expect(page).to_not have_selector("div#wid-id-2")
    end

    it '[8.12] search data incorrect time period', js: true do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.player_transaction")
      create_player_transaction
      check_player_transaction_page_js
      fill_in "start", :with => ((Time.now + 14.day).strftime("%Y-%m-%d"))
      fill_in "end", :with => (Time.now.strftime("%Y-%m-%d"))
      find("input#search").click
      expect(find("input#start").value).to eq Time.now.strftime("%Y-%m-%d")
    end

    it '[8.13] show error message when empty card ID/membership ID', js: true do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.player_transaction")
      create_player_transaction
      check_player_transaction_page_js
      fill_in "start", :with => (Time.now.strftime("%Y-%m-%d"))
      fill_in "end", :with => ((Time.now + 30.day).strftime("%Y-%m-%d"))
      find("input#search").click
      wait_for_ajax

      check_flash_message I18n.t("transaction_history.no_id")
      expect(page).to_not have_selector("div#wid-id-2")
    end
    
    it '[8.14] cannot search othoer casino transactions. (search by accounting date)', js: true do
      login_as_admin
      create_player_transaction
      @player_transaction4 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player2.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 20000, :machine_token => @machine_token1, :created_at => Time.now + 30*60, :slip_number => 2, :casino_id => 1003)
      visit home_path
      click_link I18n.t("tree_panel.player_transaction")
      check_player_transaction_page_js

      fill_search_info_js("member_id", @player2.member_id)
      fill_in "start", :with => (Shift.last.accounting_date.strftime("%F"))
      fill_in "end", :with => (Shift.last.accounting_date.strftime("%F"))
      find("input#search").click
      wait_for_ajax

      check_player_transaction_result_items([@player_transaction2])
    end
    
    it '[8.15] successfully generate report with kiosk transactions.', js: true do
      login_as_admin
      create_player_transaction
      @kiosk_id = '123456789'
      @source_type = 'everi_kiosk'
      @kiosk_transaction1 = KioskTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :transaction_type_id => 2, :ref_trans_id => @ref_trans_id, :amount => 10000, :status => 'completed', :trans_date => Time.now + 70*60, :casino_id => 20000, :kiosk_name => @kiosk_id, :source_type => @source_type, :created_at => Time.now + 70*60)
      @player_transaction4 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 2, :status => "completed", :amount => 10000, :machine_token => @machine_token1, :created_at => Time.now + 80*60, :slip_number => 1, :casino_id => 20000, :created_at => Time.now + 80*60)
      @kiosk_transaction2 = KioskTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :transaction_type_id => 2, :ref_trans_id => @ref_trans_id, :amount => 10000, :status => 'completed', :trans_date => Time.now + 90*60, :casino_id => 20000, :kiosk_name => @kiosk_id, :source_type => @source_type, :created_at => Time.now + 90*60)
      visit home_path
      click_link I18n.t("tree_panel.player_transaction")
      check_player_transaction_page_js

      fill_search_info_js("member_id", @player.member_id)
      fill_in "start", :with => (Shift.last.accounting_date.strftime("%F"))
      fill_in "end", :with => (Shift.last.accounting_date.strftime("%F"))
      find("input#search").trigger('click')
      wait_for_ajax

      check_player_transaction_result_items([@player_transaction1,@player_transaction3,@kiosk_transaction1,@player_transaction4,@kiosk_transaction2])
    end
  end
  
  describe '[16] Print Transaction report' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      mock_patron_not_change
      
      @player = create_default_player
      @player2 = create_default_player(:last_name => "player2", :member_id => "123457", :card_id => "1234567891")

      mock_wallet_balance(0.0)
    end

    after(:each) do
      PlayerTransaction.delete_all
    end
    
    it '[16.2] unauthorized print transaction report', js: true do
      login_as_test_user
      visit home_path
      set_permission(@test_user,"cashier",:player,["balance"])
      set_permission(@test_user,"cashier",:player_transaction,["search"])
      create_player_transaction
      click_link I18n.t("tree_panel.player_transaction")
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
      mock_have_active_location
      mock_patron_not_change
      reset_slip_number
      @player = create_default_player

      mock_wallet_balance(0.0)
      mock_wallet_transaction_success(:deposit)
      mock_wallet_transaction_success(:withdraw)
      mock_wallet_transaction_success(:void_deposit)
      mock_wallet_transaction_success(:void_withdraw)
      allow_any_instance_of(Requester::Patron).to receive(:validate_pin).and_return(Requester::ValidatePinResponse.new({:error_code => 'OK'}))
    end
    
    after(:each) do
    end

    def create_player_transaction
      mock_current_machine_token
      @player_transaction1 = do_deposit(1000)
      @player_transaction2 = do_deposit(1000)
      @void_transaction1 = do_void(@player_transaction1.id)
      @void_transaction2 = do_void(@player_transaction2.id)
      @player_transaction3 = do_deposit(5000)
      @void_transaction3 = do_void(@player_transaction3.id)
      @player_transaction4 = do_deposit(5000)
      sleep(1)
      @player_transaction5 = do_withdraw(5000)
      @void_transaction4 = do_void(@player_transaction5.id)
      @player_transaction6 = do_withdraw(5000)
    end
    
    it '[49.1] Show correct slip ID', :js => true do
      login_as_admin
      create_player_transaction
      visit home_path
      click_link I18n.t("tree_panel.player_transaction")
      wait_for_ajax
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
      
      @player = create_default_player
      @player2 = create_default_player(:last_name => "player2", :member_id => "123457", :card_id => "1234567891")

      mock_wallet_balance(0.0)
    end

    after(:each) do
      clean_dbs
    end

    it '[58.1] Search transaction history with card change', :js => true do
      mock_player_info_result({:error_code => 'OK', :player => {:card_id => "1234567893", :member_id => @player.member_id, :blacklist => @player.has_lock_type?('blacklist'), :pin_status => 'created', :licensee_id => 20000}})
      login_as_admin
      visit home_path
      create_player_transaction
      click_link I18n.t("tree_panel.player_transaction")
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
      mock_player_info_result({:error_code => 'OK', :player => {:card_id => 1234567893, :member_id => @player.member_id, :blacklist => @player.has_lock_type?('blacklist'), :pin_status => 'blank', :licensee_id => 20000}})
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.player_transaction")
      check_player_transaction_page
      fill_search_info("member_id", "12345678")
      find("input#search").click

      expect(find("div.widget-body label").text).to eq t("report_search.no_transaction_found")
    end
  end

  describe '[62] Promotion Credit History' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      mock_patron_not_change
      
      @player = create_default_player
      @player2 = create_default_player(:last_name => "player2", :member_id => "123457", :card_id => "1234567891")

      mock_wallet_balance(0.0)
    end

    after(:each) do
      PlayerTransaction.delete_all
    end

    it '[62.1] Show Promotion Credit History (search by accounting date)', js: true do
      login_as_admin
      create_player_transaction
      create_credit_transaction
      visit home_path
      click_link I18n.t("tree_panel.promotional_credit")
      check_player_transaction_page_js

      fill_in "start", :with => (Shift.last.accounting_date.strftime("%F"))
      fill_in "end", :with => (Shift.last.accounting_date.strftime("%F"))
      find("input#search").click
      wait_for_ajax

      check_credit_transaction_result_items([@credit_transaction1, @credit_transaction2, @credit_transaction3])
    end

    it '[62.2] Show Promotion Credit History (search by accounting date & member_id)', js: true do
      login_as_admin
      create_player_transaction
      create_credit_transaction
      visit home_path
      click_link I18n.t("tree_panel.promotional_credit")
      check_player_transaction_page_js

      fill_search_info_js("member_id", @player2.member_id)
      fill_in "start", :with => (Shift.last.accounting_date.strftime("%F"))
      fill_in "end", :with => (Shift.last.accounting_date.strftime("%F"))
      find("input#search").click
      wait_for_ajax

      check_credit_transaction_result_items([@credit_transaction2])
    end

    it '[62.3] Promotion Credit History not found', js: true do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.promotional_credit")
      check_player_transaction_page_js
      fill_in "start", :with => (Shift.last.accounting_date.strftime("%F"))
      fill_in "end", :with => (Shift.last.accounting_date.strftime("%F"))
      find("input#search").click
      wait_for_ajax

      expect(find("div.widget-body label").text).to eq t("report_search.no_transaction_found")
    end

    it '[62.4] Show Promotion Credit History fail with empty time range', js: true do
      login_as_admin
      create_player_transaction
      create_credit_transaction
      visit home_path
      click_link I18n.t("tree_panel.promotional_credit")
      check_player_transaction_page_js

      fill_in "start", :with => ("")
      fill_in "end", :with => ("")
      fill_search_info_js("member_id", @player2.member_id)
      find("input#search").click
      wait_for_ajax

      check_flash_message I18n.t("transaction_history.datetime_format_not_valid")
      expect(page).to_not have_selector("div#wid-id-2")
    end
  end
end
