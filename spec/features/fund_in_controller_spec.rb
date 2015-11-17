require "feature_spec_helper"

describe FundInController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[6] Deposit' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      mock_close_after_print
      mock_patron_not_change
      mock_have_active_location
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => "123456", :card_id => "1234567890", :currency_id => 1, :status => "active")

      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0.0)
      allow_any_instance_of(Requester::Wallet).to receive(:deposit).and_return('OK')
    end
    
    after(:each) do
      AuditLog.delete_all
      PlayerTransaction.delete_all
      Player.delete_all
    end

    it '[6.1] show Deposit page', :js => true do
      login_as_admin
      go_to_deposit_page
      wait_for_ajax
      check_title("tree_panel.fund_in")
      check_player_info
      expect(page.source).to have_selector("button#confirm_fund_in")
      expect(page.source).to have_selector("button#cancel")
    end
    
    it '[6.2] Invalid Deposit', :js => true do
      login_as_admin
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 1.111
      expect(find("input#player_transaction_amount").value).to eq "1.11"
    end

    it '[6.3] Invalid Deposit(eng)', :js => true do
      login_as_admin 
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => "abc3de"
      expect(find("input#player_transaction_amount").value).to eq ""
    end

    it '[6.4] Invalid Deposit (input 0 amount)', :js => true do
      login_as_admin 
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 0
      find("button#confirm_fund_in").click

      find("div#pop_up_dialog")[:style].include?("block").should == false
      expect(find("label.invisible_error").text).to eq I18n.t("invalid_amt.deposit")
    end

    it '[6.5] cancel Deposit', :js => true do
      login_as_admin 
      go_to_deposit_page
      find("a#cancel").click
      
      wait_for_ajax
      check_balance_page
    end

    it '[6.6] Confirm Deposit', :js => true do
      login_as_admin 
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_fund_in").click

      find("div#pop_up_dialog")[:style].include?("block").should == true
      find("div#pop_up_dialog")[:class].include?("fadeIn").should == true
      
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
    end

    it '[6.7] cancel dialog box Deposit', :js => true do
      login_as_admin  
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_fund_in").click

      find("div#pop_up_dialog")[:style].include?("block").should == true
      find("div#pop_up_dialog")[:class].include?("fadeIn").should == true
      
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")

      find("div#pop_up_dialog div button#cancel").click
      find("div#pop_up_dialog")[:class].include?("fadeOut").should == true
      sleep(5)
      find("div#pop_up_dialog")[:style].include?("none").should == true
      
    end

    it '[6.8] Confirm dialog box Deposit', :js => true do
      login_as_admin 
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_fund_in").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      find("div#pop_up_dialog div button#confirm").click
      
      check_title("tree_panel.fund_in")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
    end

    it '[6.9] audit log for confirm dialog box Deposit', :js => true do
      login_as_admin
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_fund_in").click
      find("div#pop_up_dialog div button#confirm").click
      wait_for_ajax
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
      
      audit_log = AuditLog.last
      audit_log.should_not be_nil
      audit_log.audit_target.should == "player"
      audit_log.action_by.should == @root_user.name
      audit_log.action_type.should == "update"
      audit_log.action.should == "deposit"
      audit_log.action_status.should == "success"
      audit_log.action_error.should be_nil
      audit_log.ip.should_not be_nil
      audit_log.session_id.should_not be_nil
      audit_log.description.should_not be_nil
    end

    it '[6.10] click unauthorized action (Deposit)', :js => true do
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["balance"])
      set_permission(@test_user,"cashier",:player_transaction,["deposit"])
      visit home_path
      click_link I18n.t("tree_panel.balance")
      fill_search_info_js("member_id", @player.member_id)
      find("#button_find").click
      
      check_balance_page
      check_player_info
      set_permission(@test_user,"cashier",:player,[])
      set_permission(@test_user,"cashier",:player_transaction,[])
      sleep(5)
      within "div#content" do
        click_link I18n.t("button.deposit")
      end

      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end

    it '[6.11] click link to the unauthorized page' do
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player_transaction,[])
      visit fund_in_path + "?member_id=#{@player.member_id}"
      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end

    it '[6.12] click unauthorized action (confirm dialog box Deposit)', :js => true do
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["balance"])
      set_permission(@test_user,"cashier",:player_transaction,["deposit"])
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_fund_in").click
      set_permission(@test_user,"cashier",:player_transaction,[])
      find("div#pop_up_dialog div button#confirm").click
      wait_for_ajax

      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end
    
    it '[6.13] click unauthorized action (print slip)', :js => true do
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player_transaction,["deposit"])
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_fund_in").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      find("div#pop_up_dialog")[:class].include?("fadeIn").should == true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      find("div#pop_up_dialog div button#confirm").click
      
      check_title("tree_panel.fund_in")
      expect(page).to have_selector("table")
      expect(page).to_not have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
    end

    it '[6.14] Print slip', :js => true do
      login_as_admin
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_fund_in").click

      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      find("div#pop_up_dialog")[:class].include?("fadeIn").should == true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      find("div#pop_up_dialog div button#confirm").click
      
      check_title("tree_panel.fund_in")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")

      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(100.0)
      
      find("button#print_slip").click
      expect(page.source).to have_selector("iframe")
      wait_for_ajax
      check_balance_page(10000)
    end

    it '[6.15] Close slip', :js => true do
      login_as_admin 
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_fund_in").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      find("div#pop_up_dialog")[:class].include?("fadeIn").should == true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      find("div#pop_up_dialog div button#confirm").click
      
      check_title("tree_panel.fund_in")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
      
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(100.0)

      find("a#close_link").click
      wait_for_ajax
      check_balance_page(10000)
    end
    
    it '[6.16] audit log for print slip', :js => true do
      login_as_admin 
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_fund_in").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      find("div#pop_up_dialog")[:class].include?("fadeIn").should == true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      find("div#pop_up_dialog div button#confirm").click
      
      check_title("tree_panel.fund_in")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
      mock_close_after_print

      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(100.0)
      
      find("button#print_slip").click
      expect(page.source).to have_selector("iframe")
      wait_for_ajax
      check_balance_page(10000)
      
      audit_log = AuditLog.find_by_audit_target("player_transaction")
      audit_log.should_not be_nil
      audit_log.audit_target.should == "player_transaction"
      audit_log.action_by.should == @root_user.name
      audit_log.action_type.should == "read"
      audit_log.action.should == "print"
      audit_log.action_status.should == "success"
      audit_log.action_error.should be_nil
      audit_log.ip.should_not be_nil
      audit_log.session_id.should_not be_nil
      audit_log.description.should_not be_nil
    end

    it '[6.17] Invalid Deposit (empty)', :js => true do
      login_as_admin  
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => ""
      find("button#confirm_fund_in").click
      find("div#pop_up_dialog")[:style].include?("block").should == false
      expect(find("label.invisible_error").text).to eq I18n.t("invalid_amt.deposit")
    end
  end

  describe '[28] Unauthorized permission without location (Deposit, Withdraw)' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      mock_close_after_print
      mock_patron_not_change
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => "123456", :card_id => "1234567890", :currency_id => 1, :status => "active")

      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0.0)
      allow_any_instance_of(Requester::Wallet).to receive(:deposit).and_return('OK')
    end
    
    after(:each) do
      AuditLog.delete_all
      PlayerTransaction.delete_all
      Player.delete_all
    end

    it '[28.1] Disappear deposit, withdraw button', :js => true do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.balance")
      wait_for_ajax
      fill_search_info_js("member_id", @player.member_id)
      
      find("#button_find").click
      check_balance_page

      expect(page.source).to_not have_selector("#balance_deposit")
      expect(page.source).to_not have_selector("#balance_withdraw")
    end
  end
end
