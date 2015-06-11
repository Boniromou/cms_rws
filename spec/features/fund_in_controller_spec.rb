require "feature_spec_helper"

describe FundInController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
    @root_user = User.create!(:uid => 1, :employee_id => 'portal.admin')
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
      @player = Player.create!(:player_name => "test", :member_id => "123456", :card_id => "1234567890", :currency_id => 1, :status => "active")
      TransactionType.create!(:name => "Deposit")

      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(0.0)
      allow_any_instance_of(Requester::Standard).to receive(:deposit).and_return('OK')
    end
    
    after(:each) do
      AuditLog.delete_all
      PlayerTransaction.delete_all
      Player.delete_all
    end

    it '[6.1] show Deposit page' do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.balance")
      fill_search_info("member_id", @player.member_id)
      find("#button_find").click
      check_balance_page

      within "div#content" do
        click_link I18n.t("button.deposit")
      end
      check_title("tree_panel.fund_in")
      check_player_info
      expect(page.source).to have_selector("button#confirm")
      expect(page.source).to have_selector("button#cancel")
    end
    
    it '[6.2] Invalid Deposit', :js => true do
      login_as_admin 
      visit fund_in_path + "?member_id=#{@player.member_id}"
      fill_in "player_transaction_amount", :with => 1.111
      expect(find("input#player_transaction_amount").value).to eq "1.11"
    end

    it '[6.3] Invalid Deposit(eng)', :js => true do
      login_as_admin 
      visit fund_in_path + "?member_id=#{@player.member_id}"
      fill_in "player_transaction_amount", :with => "abc3de"
      expect(find("input#player_transaction_amount").value).to eq ""
    end

    it '[6.4] Invalid Deposit (input 0 amount)', :js => true do
      login_as_admin 
      visit fund_in_path + "?member_id=#{@player.member_id}"
      fill_in "player_transaction_amount", :with => 0
      within "div#button_set" do
        click_button I18n.t("button.confirm")
      end
      find("div#confirm_fund_dialog")[:style].include?("block").should == false
      expect(find("label.invisible_error").text).to eq I18n.t("invalid_amt.deposit")
    end

    it '[6.5] cancel Deposit', :js => true do
      login_as_admin 
      visit fund_in_path + "?member_id=#{@player.member_id}"
      find("a#cancel").click
      
      wait_for_ajax
      check_balance_page
    end

    it '[6.6] Confirm Deposit', :js => true do
      login_as_admin 
      visit fund_in_path + "?member_id=#{@player.member_id}"
      fill_in "player_transaction_amount", :with => 100
      within "div#button_set" do
        click_button I18n.t("button.confirm")
      end
      find("div#confirm_fund_dialog")[:style].include?("block").should == true
      find("div#button_set button#confirm")[:disabled].should == "disabled"
      find("a#cancel")[:disabled].should == "disabled"
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#confirm_fund_dialog div button#confirm")
      expect(page).to have_selector("div#confirm_fund_dialog div button#cancel")
    end

    it '[6.7] cancel dialog box Deposit', :js => true do
      login_as_admin 
      visit fund_in_path + "?member_id=#{@player.member_id}"
      fill_in "player_transaction_amount", :with => 100
      within "div#button_set" do
        click_button I18n.t("button.confirm")
      end
      find("div#confirm_fund_dialog")[:style].include?("block").should == true
      find("div#button_set button#confirm")[:disabled].should == "disabled"
      find("a#cancel")[:disabled].should == "disabled"
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#confirm_fund_dialog div button#confirm")
      expect(page).to have_selector("div#confirm_fund_dialog div button#cancel")
      find("div#confirm_fund_dialog div button#cancel").click
      find("div#confirm_fund_dialog")[:style].include?("none").should == true
      find("div#button_set button#confirm")[:disabled].should be_nil
      find("a#cancel")[:disabled].should be_nil
    end


    it '[6.8] Confirm Deposit', :js => true do
      login_as_admin 
      visit fund_in_path + "?member_id=#{@player.member_id}"
      fill_in "player_transaction_amount", :with => 100
      within "div#button_set" do
        click_button I18n.t("button.confirm")
      end
      expect(find("div#confirm_fund_dialog")[:style].include?("block")).to eq true
      find("div#button_set button#confirm")[:disabled].should == "disabled"
      find("a#cancel")[:disabled].should == "disabled"
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#confirm_fund_dialog div button#confirm")
      expect(page).to have_selector("div#confirm_fund_dialog div button#cancel")
      find("div#confirm_fund_dialog div button#confirm").click
      
      check_title("tree_panel.fund_in")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
    end

    it '[6.9] audit log for confirm dialog box Deposit', :js => true do
      login_as_admin 
      visit fund_in_path + "?member_id=" + @player.member_id
      fill_in "player_transaction_amount", :with => 100
      within "div#button_set" do
        click_button I18n.t("button.confirm")
      end
      find("div#confirm_fund_dialog div button#confirm").click
      wait_for_ajax
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
      
      audit_log = AuditLog.last
      audit_log.should_not be_nil
      audit_log.audit_target.should == "player"
      audit_log.action_by.should == @root_user_name
      audit_log.action_type.should == "update"
      audit_log.action.should == "deposit"
      audit_log.action_status.should == "success"
      audit_log.action_error.should be_nil
      audit_log.ip.should_not be_nil
      audit_log.session_id.should_not be_nil
      audit_log.description.should_not be_nil
    end

    it '[6.10] click unauthorized action (Deposit)' do
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["balance"])
      set_permission(@test_user,"cashier",:player_transaction,["deposit"])
      visit home_path
      click_link I18n.t("tree_panel.balance")
      fill_search_info("member_id", @player.member_id)
      find("#button_find").click
      
      check_balance_page
      check_player_info
      set_permission(@test_user,"cashier",:player,[])
      set_permission(@test_user,"cashier",:player_transaction,[])

      find("div a#balance_deposit").click

      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end

    it '[6.11] click link to the unauthorized page' do
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player_transaction,[])
      visit fund_in_path + "?member_id=#{@player.member_id}"
      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end

    it '[6.12] click unauthorized action (confirm dialog box Deposit)', :js => true do
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["balance"])
      set_permission(@test_user,"cashier",:player_transaction,["deposit"])
      visit fund_in_path + "?member_id=" + @player.member_id
      fill_in "player_transaction_amount", :with => 100
      within "div#button_set" do
        click_button I18n.t("button.confirm")
      end
      set_permission(@test_user,"cashier",:player_transaction,[])
      find("div#confirm_fund_dialog div button#confirm").click
      wait_for_ajax

      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end
    
    it '[6.13] click unauthorized action (print slip)', :js => true do
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player_transaction,["deposit"])
      visit fund_in_path + "?member_id=#{@player.member_id}"
      fill_in "player_transaction_amount", :with => 100
      within "div#button_set" do
        click_button I18n.t("button.confirm")
      end
      expect(find("div#confirm_fund_dialog")[:style].include?("block")).to eq true
      find("div#button_set button#confirm")[:disabled].should == "disabled"
      find("a#cancel")[:disabled].should == "disabled"
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#confirm_fund_dialog div button#confirm")
      expect(page).to have_selector("div#confirm_fund_dialog div button#cancel")
      find("div#confirm_fund_dialog div button#confirm").click
      
      check_title("tree_panel.fund_in")
      expect(page).to have_selector("table")
      expect(page).to_not have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
    end

    it '[6.14] Print slip', :js => true do
      login_as_admin 
      visit fund_in_path + "?member_id=#{@player.member_id}"
      fill_in "player_transaction_amount", :with => 100
      within "div#button_set" do
        click_button I18n.t("button.confirm")
      end
      expect(find("div#confirm_fund_dialog")[:style].include?("block")).to eq true
      find("div#button_set button#confirm")[:disabled].should == "disabled"
      find("a#cancel")[:disabled].should == "disabled"
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#confirm_fund_dialog div button#confirm")
      expect(page).to have_selector("div#confirm_fund_dialog div button#cancel")
      find("div#confirm_fund_dialog div button#confirm").click
      
      check_title("tree_panel.fund_in")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")

      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(100.0)
      
      find("button#print_slip").click
      expect(page.source).to have_selector("iframe")
      wait_for_ajax
      check_balance_page(10000)
    end

    it '[6.15] Close slip', :js => true do
      login_as_admin 
      visit fund_in_path + "?member_id=#{@player.member_id}"
      fill_in "player_transaction_amount", :with => 100
      within "div#button_set" do
        click_button I18n.t("button.confirm")
      end
      expect(find("div#confirm_fund_dialog")[:style].include?("block")).to eq true
      find("div#button_set button#confirm")[:disabled].should == "disabled"
      find("a#cancel")[:disabled].should == "disabled"
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#confirm_fund_dialog div button#confirm")
      expect(page).to have_selector("div#confirm_fund_dialog div button#cancel")
      find("div#confirm_fund_dialog div button#confirm").click
      
      check_title("tree_panel.fund_in")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
      
      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(100.0)

      find("a#close_link").click
      wait_for_ajax
      check_balance_page(10000)
    end
    
    it '[6.16] audit log for print slip', :js => true do
      login_as_admin 
      visit fund_in_path + "?member_id=#{@player.member_id}"
      fill_in "player_transaction_amount", :with => 100
      within "div#button_set" do
        click_button I18n.t("button.confirm")
      end
      expect(find("div#confirm_fund_dialog")[:style].include?("block")).to eq true
      find("div#button_set button#confirm")[:disabled].should == "disabled"
      find("a#cancel")[:disabled].should == "disabled"
      expect(find("#fund_amt").text).to eq to_display_amount_str(10000)
      expect(page).to have_selector("div#confirm_fund_dialog div button#confirm")
      expect(page).to have_selector("div#confirm_fund_dialog div button#cancel")
      find("div#confirm_fund_dialog div button#confirm").click
      
      check_title("tree_panel.fund_in")
      expect(page).to have_selector("table")
      expect(page).to have_selector("button#print_slip")
      expect(page).to have_selector("a#close_link")
      mock_close_after_print

      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(100.0)
      
      find("button#print_slip").click
      expect(page.source).to have_selector("iframe")
      wait_for_ajax
      check_balance_page(10000)
      
      audit_log = AuditLog.find_by_audit_target("player_transaction")
      audit_log.should_not be_nil
      audit_log.audit_target.should == "player_transaction"
      audit_log.action_by.should == @root_user.employee_id
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
      visit fund_in_path + "?member_id=#{@player.member_id}"
      fill_in "player_transaction_amount", :with => ""
      within "div#button_set" do
        click_button I18n.t("button.confirm")
      end
      find("div#confirm_fund_dialog")[:style].include?("block").should == false
      expect(find("label.invisible_error").text).to eq I18n.t("invalid_amt.deposit")
    end
  end
end
