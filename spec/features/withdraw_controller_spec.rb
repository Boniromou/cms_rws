require "feature_spec_helper"

describe WithdrawController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[7] Withdraw' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      mock_close_after_print
      mock_patron_not_change
      mock_have_active_location
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => "123456", :card_id => "1234567890", :currency_id => 2, :status => "active", :property_id => 20000)
      @player_balance = 20000
      mock_wallet_balance(200.0)
      mock_wallet_transaction_success(:withdraw)
      allow_any_instance_of(Requester::Patron).to receive(:validate_pin).and_return({})
      allow_any_instance_of(RequesterHelper).to receive(:validate_pin).and_return(true)
    end
    
    after(:each) do
      AuditLog.delete_all
      PlayerTransaction.delete_all
      Player.delete_all
    end

    it '[7.1] show Withdraw page', :js => true do
      login_as_admin
      go_to_withdraw_page
      wait_for_ajax
      check_title("tree_panel.fund_out")
      check_player_info
      expect(page.source).to have_selector("button#confirm")
      expect(page.source).to have_selector("button#cancel")
    end
    
    it '[7.2] Invalid Withdraw', :js => true do
      login_as_admin 
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => 1.111
      expect(find("input#player_transaction_amount").value).to eq "1.11"
    end

    it '[7.3] Invalid Withdraw(eng)', :js => true do
      login_as_admin 
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => "abc3de"
      expect(find("input#player_transaction_amount").value).to eq ""
    end

    it '[7.4] Invalid Withdraw (input 0 amount)', :js => true do
      login_as_admin 
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => ""
      find("button#confirm_withdraw").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq false
      expect(find("label.invisible_error").text).to eq I18n.t("invalid_amt.withdraw")
    end

    it '[7.5] Invalid Withdraw (invalid balance)', :js => true do
      allow_any_instance_of(Requester::Wallet).to receive(:withdraw).and_raise(Remote::AmountNotEnough.new("200.0"))

      login_as_admin 
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => 300
      find("button#confirm_withdraw").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      find("div#pop_up_dialog div button#confirm").click
      check_title("tree_panel.fund_out")
      expect(find("label#player_full_name").text).to eq @player.full_name.upcase
      expect(find("label#player_member_id").text).to eq @player.member_id.to_s
      check_flash_message I18n.t("invalid_amt.no_enough_to_withdraw", { balance: to_display_amount_str(@player_balance)})
    end

    it '[7.6] cancel Withdraw', :js => true do
      login_as_admin 
      go_to_withdraw_page
      find("a#cancel").click

      wait_for_ajax
      check_balance_page(@player_balance)
    end

    it '[7.7] Confirm Withdraw', :js => true do
      login_as_admin  
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_withdraw").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
    end

    it '[7.8] Cancel dialog box Withdraw', :js => true do
      login_as_admin 
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_withdraw").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      find("div#pop_up_dialog div button#cancel").trigger('click')
      sleep(5)
      expect(find("div#pop_up_dialog")[:class].include?("fadeOut")).to eq true
      expect(find("div#pop_up_dialog")[:style].include?("none")).to eq true   
    end


    it '[7.9] Confirm dialog box Withdraw', :js => true do
      login_as_admin 
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_withdraw").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      find("div#pop_up_dialog div button#confirm").click
      check_title("tree_panel.fund_out")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
    end

    it '[7.10] audit log for confirm dialog box Withdraw', :js => true do
      login_as_admin 
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_withdraw").click
      find("div#pop_up_dialog div button#confirm").click
      wait_for_ajax
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
      
      audit_log = AuditLog.find_by_audit_target("player")
      expect(audit_log).to_not eq nil
      expect(audit_log.audit_target).to eq "player"
      expect(audit_log.action_by).to eq @root_user.name
      expect(audit_log.action_type).to eq "update"
      expect(audit_log.action).to eq "withdraw"
      expect(audit_log.action_status).to eq "success"
      expect(audit_log.action_error).to eq nil
      expect(audit_log.ip).to_not eq nil
      expect(audit_log.session_id).to_not eq nil
      expect(audit_log.description).to_not eq nil
    end

    it '[7.11] click unauthorized action (Withdraw)' do
      @test_user = User.create!(:uid => 2, :name => 'test.user', :property_id => 20000)
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["balance"])
      set_permission(@test_user,"cashier",:player_transaction,["withdraw"])
      visit home_path
      click_link I18n.t("tree_panel.balance")
      fill_search_info("member_id", @player.member_id)
      find("#button_find").click
      
      expect(find("label#player_full_name").text).to eq @player.full_name.upcase
      expect(find("label#player_member_id").text).to eq @player.member_id.to_s
      expect(find("label#player_balance").text).to eq to_display_amount_str(@player_balance)
      set_permission(@test_user,"cashier",:player,[])
      set_permission(@test_user,"cashier",:player_transaction,[])

      find("div a#balance_withdraw").click

      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end

    it '[7.12] click link to the unauthorized page' do
      @test_user = User.create!(:uid => 2, :name => 'test.user', :property_id => 20000)
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player_transaction,[])
      visit fund_out_path + "?member_id=#{@player.member_id}"
      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end

    it '[7.13] click unauthorized action (confirm dialog box Withdraw)', :js => true do
      @test_user = User.create!(:uid => 2, :name => 'test.user', :property_id => 20000)
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["balance"])
      set_permission(@test_user,"cashier",:player_transaction,["withdraw"])
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_withdraw").click
      set_permission(@test_user,"cashier",:player_transaction,[])
      find("div#pop_up_dialog div button#confirm").click
      wait_for_ajax

      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end
    
    it '[7.14] click unauthorized action (print slip)', :js => true do
      @test_user = User.create!(:uid => 2, :name => 'test.user', :property_id => 20000)
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player_transaction,["withdraw"])
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_withdraw").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      find("div#pop_up_dialog div button#confirm").click
      
      check_title("tree_panel.fund_out")
      expect(page).to have_selector("table")
      expect(page).to_not have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
    end

    it '[7.15] Print slip', :js => true do
      login_as_admin
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_withdraw").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      find("div#pop_up_dialog div button#confirm").click
      
      check_title("tree_panel.fund_out")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")

      mock_wallet_balance(100.0)

      find("button#print_slip").click
      expect(page.source).to have_selector("iframe")
      wait_for_ajax
      check_balance_page(@player_balance - 10000)
    end

    it '[7.16] Close slip', :js => true do
      login_as_admin 
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_withdraw").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      find("div#pop_up_dialog div button#confirm").click
      
      check_title("tree_panel.fund_out")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
      
      mock_wallet_balance(100.0)

      find("a#close_link").click
      wait_for_ajax
      check_balance_page(@player_balance - 10000)
    end
    
    it '[7.17] audit log for print slip', :js => true do
      login_as_admin 
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_withdraw").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      find("div#pop_up_dialog div button#confirm").click
      
      check_title("tree_panel.fund_out")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
      
      mock_wallet_balance(100.0)

      find("button#print_slip").click
      expect(page.source).to have_selector("iframe")
      wait_for_ajax
      check_balance_page(@player_balance - 10000)
      
      audit_log = AuditLog.find_by_audit_target("player_transaction")
      expect(audit_log).to_not eq nil
      expect(audit_log.audit_target).to eq "player_transaction"
      expect(audit_log.action_by).to eq @root_user.name
      expect(audit_log.action_type).to eq "read"
      expect(audit_log.action).to eq "print"
      expect(audit_log.action_status).to eq "success"
      expect(audit_log.action_error).to eq nil
      expect(audit_log.ip).to_not eq nil
      expect(audit_log.session_id).to_not eq nil
      expect(audit_log.description).to_not eq nil
    end
    
    it '[7.18] Invalid Withdrawal (empty)', :js => true do
      login_as_admin 
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => ""
      find("button#confirm_withdraw").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq false
      expect(find("label.invisible_error").text).to eq I18n.t("invalid_amt.withdraw")
    end
  end

  describe '[52] Enter PIN withdraw success ' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      mock_close_after_print
      mock_patron_not_change
      mock_have_active_location
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => "123456", :card_id => "1234567890", :currency_id => 2, :status => "active", :property_id => 20000)
      @player_balance = 20000
      mock_wallet_balance(200.0)
      mock_wallet_transaction_success(:withdraw)
    end

    after(:each) do
      AuditLog.delete_all
      PlayerTransaction.delete_all
      Player.delete_all
    end

    it '[52.1] Enter PIN withdraw success', :js => true do
      allow_any_instance_of(Requester::Patron).to receive(:validate_pin).and_return({})
      login_as_admin 
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_withdraw").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      expect(page).to have_selector("div#pop_up_dialog div label#pin_label")
      expect(page).to have_selector("div#pop_up_dialog div label#pin_label")
      expect(page).to have_selector("div#pop_up_dialog div input#player_transaction_pin")
      fill_in "player_transaction_pin", :with => 1111
      find("div#pop_up_dialog div button#confirm").click
      check_title("tree_panel.fund_out")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
    end

    it '[52.2] Enter PIN withdraw fail with wrong PIN', :js => true do
      allow_any_instance_of(Requester::Patron).to receive(:validate_pin).and_raise(Remote::PinError)
      login_as_admin 
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_withdraw").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      expect(page).to have_selector("div#pop_up_dialog div label#pin_label")
      expect(page).to have_selector("div#pop_up_dialog div label#pin_label")
      expect(page).to have_selector("div#pop_up_dialog div input#player_transaction_pin")
      fill_in "player_transaction_pin", :with => 1111
      find("div#pop_up_dialog div button#confirm").click
      check_flash_message I18n.t("invalid_pin.invalid_pin")
      check_title("tree_panel.balance")
      # expect(page).to have_selector("table")
      # expect(page).to have_selector("button#print_slip")
      # expect(page).to have_selector("a#close_link")
    end
  end
end
