require "feature_spec_helper"

describe DepositController do
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
      @player = create_default_player

      mock_wallet_balance(0.0)
      mock_wallet_transaction_success(:deposit)
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
      expect(page.source).to have_selector("button#confirm_deposit")
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
      find("#player_transaction_payment_method_type option[value='2']").select_option
      find("#player_transaction_source_of_funds option[value='2']").select_option
      find("button#confirm_deposit").click

      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq  false
      expect(find("label#amount_error").text).to eq I18n.t("invalid_amt.deposit")
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
      # select("Cash", :from => "payment_method_type")
      # select("Marker", :from => "source_of_funds")
      find("#player_transaction_payment_method_type option[value='2']").select_option
      find("#player_transaction_source_of_funds option[value='2']").select_option


      find("button#confirm_deposit").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true

      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
    end

    it '[6.7] cancel dialog box Deposit', :js => true do
      login_as_admin
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 100
      find("#player_transaction_payment_method_type option[value='2']").select_option
      find("#player_transaction_source_of_funds option[value='2']").select_option
      find("button#confirm_deposit").click

      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true

      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")

      find("div#pop_up_dialog div button#cancel").click
      expect(find("div#pop_up_dialog")[:class].include?("fadeOut")).to eq true
      sleep(5)
      expect(find("div#pop_up_dialog")[:style].include?("none")).to eq true

    end

#deposit success
    it '[6.8] Confirm dialog box Deposit', :js => true do
      login_as_admin
      go_to_deposit_page
      wait_for_ajax
      check_remain_amount(:deposit)
      fill_in "player_transaction_amount", :with => 100
      find("#player_transaction_payment_method_type option[value='2']").select_option
      find("#player_transaction_source_of_funds option[value='2']").select_option
      find("button#confirm_deposit").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true

      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      expect(find('label#remain_limit_alert')[:style]).to_not have_content 'visible'
      find("div#pop_up_dialog div button#confirm").click

      expect(first("div div h1").text).to include I18n.t("tree_panel.fund_in")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
    end

    it '[6.9] audit log for confirm dialog box Deposit', :js => true do
      login_as_admin
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 100
      find("#player_transaction_payment_method_type option[value='2']").select_option
      find("#player_transaction_source_of_funds option[value='2']").select_option
      find("button#confirm_deposit").click
      find("div#pop_up_dialog div button#confirm").click
      wait_for_ajax
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")

      audit_log = AuditLog.last
      expect(audit_log).to_not eq nil
      expect(audit_log.audit_target).to eq "player"
      expect(audit_log.action_by).to eq @root_user.name
      expect(audit_log.action_type).to eq "update"
      expect(audit_log.action).to eq "deposit"
      expect(audit_log.action_status).to eq "success"
      expect(audit_log.action_error).to eq nil
      expect(audit_log.ip).to_not eq nil
      expect(audit_log.session_id).to_not eq nil
      expect(audit_log.description).to_not eq nil
    end

    it '[6.10] click unauthorized action (Deposit)', :js => true do
      login_as_test_user
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
      login_as_test_user
      set_permission(@test_user,"cashier",:player_transaction,[])
      visit fund_in_path + "?member_id=#{@player.member_id}"
      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end

    it '[6.12] click unauthorized action (confirm dialog box Deposit)', :js => true do
      login_as_test_user
      set_permission(@test_user,"cashier",:player,["balance"])
      set_permission(@test_user,"cashier",:player_transaction,["deposit"])
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 100
      find("#player_transaction_payment_method_type option[value='2']").select_option
      find("#player_transaction_source_of_funds option[value='2']").select_option
      find("button#confirm_deposit").click
      set_permission(@test_user,"cashier",:player_transaction,[])
      find("div#pop_up_dialog div button#confirm").click
      wait_for_ajax

      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end

    it '[6.13] click unauthorized action (print slip)', :js => true do
      login_as_test_user
      set_permission(@test_user,"cashier",:player_transaction,["deposit"])
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 100
      find("#player_transaction_payment_method_type option[value='2']").select_option
      find("#player_transaction_source_of_funds option[value='2']").select_option
      find("button#confirm_deposit").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      find("div#pop_up_dialog div button#confirm").click

      expect(first("div div h1").text).to include I18n.t("tree_panel.fund_in")
      expect(page).to have_selector("table")
      expect(page).to_not have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
    end

    it '[6.14] Print slip', :js => true do
      login_as_admin
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 100
      find("#player_transaction_payment_method_type option[value='2']").select_option
      find("#player_transaction_source_of_funds option[value='2']").select_option
      find("button#confirm_deposit").click

      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      find("div#pop_up_dialog div button#confirm").click

      expect(first("div div h1").text).to include I18n.t("tree_panel.fund_in")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")

      mock_wallet_balance(100.0)

      find("button#print_slip").click
      expect(page.source).to have_selector("iframe")
      wait_for_ajax
      check_balance_page(10000)
    end

    it '[6.15] Close slip', :js => true do
      login_as_admin
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 100
      find("#player_transaction_payment_method_type option[value='2']").select_option
      find("#player_transaction_source_of_funds option[value='2']").select_option
      find("button#confirm_deposit").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      find("div#pop_up_dialog div button#confirm").click

      expect(first("div div h1").text).to include I18n.t("tree_panel.fund_in")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")

      mock_wallet_balance(100.0)

      find("a#close_link").click
      wait_for_ajax
      check_balance_page(10000)
    end

    it '[6.16] audit log for print slip', :js => true do
      login_as_admin
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 100
      find("#player_transaction_payment_method_type option[value='2']").select_option
      find("#player_transaction_source_of_funds option[value='2']").select_option
      find("button#confirm_deposit").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      find("div#pop_up_dialog div button#confirm").click

      expect(first("div div h1").text).to include I18n.t("tree_panel.fund_in")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
      mock_close_after_print

      mock_wallet_balance(100.0)

      find("button#print_slip").click
      expect(page.source).to have_selector("iframe")
      wait_for_ajax
      check_balance_page(10000)

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

    it '[6.17] Invalid Deposit (empty)', :js => true do
      login_as_admin
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => ""
      find("#player_transaction_payment_method_type option[value='2']").select_option
      find("#player_transaction_source_of_funds option[value='2']").select_option
      find("button#confirm_deposit").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq false
      expect(find("label#amount_error").text).to eq I18n.t("invalid_amt.deposit")
    end

    it '[6.18] Update trans date', :js => true do
      trans_date = (Time.now + 5.second).strftime("%Y-%m-%d %H:%M:%S")
      wallet_response = Requester::WalletTransactionResponse.new({:error_code => 'OK', :error_message => 'Request is carried out successfully.', :trans_date => trans_date})
      allow_any_instance_of(Requester::Wallet).to receive(:deposit).and_return(wallet_response)
      login_as_admin
      do_deposit(100)
      transaction = PlayerTransaction.first
      expect(transaction.trans_date).to eq trans_date.to_time(:local).utc
    end

    # it '[6.21] Deposit success with over limit', :js => true do
    #   login_as_admin
    #   go_to_deposit_page
    #   wait_for_ajax
    #   check_remain_amount(:deposit)
    #   fill_in "player_transaction_amount", :with => 300000
    #   find("#player_transaction_payment_method_type option[value='2']").select_option
    #   find("#player_transaction_source_of_funds option[value='2']").select_option
    #   find("button#confirm_deposit").click
    #   expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true

    #   expect(find("#fund_amt").text).to eq to_display_amount_str(30000000)
    #   expect(page).to have_selector("div#pop_up_dialog div button#confirm")
    #   expect(page).to have_selector("div#pop_up_dialog div button#cancel")
    #   content_list = [I18n.t("deposit_withdrawal.exceed_remain_limit")]
    #   click_pop_up_confirm("confirm_deposit", content_list) do
    #     expect(find('label#remain_limit_alert')[:style]).to have_content 'visible'
    #   end

    #   expect(first("div div h1").text).to include I18n.t("tree_panel.fund_in")
    #   expect(page).to have_selector("table")
    #   expect(page).to have_selector("button#print_slip")
    #   expect(page).to have_selector("a#close_link")
    # end

    it '[6.22] Confirm Deposit, need authorize', :js => true do
      login_as_admin
      go_to_deposit_page
      fill_in "player_transaction_amount", :with => 70000
      find("#player_transaction_payment_method_type option[value='2']").select_option
      find("#player_transaction_source_of_funds option[value='2']").select_option


      find("button#confirm_deposit").click
      expect(find("div#pop_up_dialog")[:style].include?("block")).to eq true
      expect(find("div#pop_up_dialog")[:class].include?("fadeIn")).to eq true

      expect(find("#fund_amt").text).to eq to_display_amount_str(7000000)
      expect(page).to have_selector("div#pop_up_dialog div button#confirm")
      expect(page).to have_selector("div#pop_up_dialog div button#cancel")
      expect(find("#authorize_alert")[:style].include?("block")).to eq true
    end
  end

  describe '[28] Unauthorized permission without location (Deposit, Withdraw)' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      mock_close_after_print
      mock_patron_not_change
      @player = create_default_player

      mock_wallet_balance(0.0)
      mock_wallet_transaction_success(:deposit)
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
