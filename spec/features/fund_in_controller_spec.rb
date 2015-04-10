require "feature_spec_helper"

describe FundInController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
    User.delete_all
    @root_user = User.create!(:uid => 1, :employee_id => 'portal.admin')
  end

  after(:all) do
    User.delete_all
    Warden.test_reset!
  end

  describe '[6] Deposit' do
    before(:each) do
      Player.delete_all
      PlayerTransaction.delete_all
      @player = Player.create!(:player_name => "test", :member_id => 123456, :currency_id => 1,:balance => 0, :status => "unlock")
    end
    
    after(:each) do
      Player.delete_all
      PlayerTransaction.delete_all
    end

    it '[6.1] show Deposit page' do
      login_as(@root_user)
      visit home_path
      click_link I18n.t("tree_panel.balance")
      fill_in "player_member_id", :with => @player.member_id
      click_button I18n.t("button.find")
      check_title("tree_panel.balance")

      within "div#content" do
        click_link I18n.t("button.deposit")
      end
      check_title("tree_panel.fund_in")
      expect(find("label#player_name").text).to eq @player.player_name
      expect(find("label#player_member_id").text).to eq @player.member_id.to_s
      expect(page.source).to have_selector("button#confirm")
      expect(page.source).to have_selector("button#cancel")
    end
    
    it '[6.2] Invalid Deposit', :js => true do
      login_as(@root_user) 
      visit fund_in_path + "?member_id=#{@player.member_id}"
      fill_in "player_transaction_amount", :with => 0.111
      expect(find("input#player_transaction_amount").value).to eq "0.11"
    end

    it '[6.3] Invalid Deposit(eng)', :js => true do
      login_as(@root_user) 
      visit fund_in_path + "?member_id=#{@player.member_id}"
      fill_in "player_transaction_amount", :with => "abc3de"
      expect(find("input#player_transaction_amount").value).to eq ""
    end

    it '[6.4] Invalid Deposit (input 0 amount)', :js => true do
      login_as(@root_user) 
      visit fund_in_path + "?member_id=#{@player.member_id}"
      fill_in "player_transaction_amount", :with => 0
      click_button I18n.t("button.confirm")
      find("div#confirm_fund_dialog")[:style].include?("block").should == true
      find("div#confirm_fund_dialog div button#confirm").click
      wait_for_ajax
      check_title("tree_panel.fund_in")
      expect(find("label#player_name").text).to eq @player.player_name
      expect(find("label#player_member_id").text).to eq @player.member_id.to_s
      check_flash_message I18n.t("invalid_amt.deposit")
    end

    it '[6.5] cancel Deposit' do
      login_as(@root_user) 
      visit fund_in_path + "?member_id=#{@player.member_id}"
      find("div#button_set form input#cancel").click

      check_title("tree_panel.home")
    end

    it '[6.8] Confirm Deposit' do
      login_as(@root_user) 
      visit fund_in_path + "?member_id=#{@player.member_id}"
      fill_in "player_transaction_amount", :with => 100
      click_button "hidden_confirm"
      
      check_title("tree_panel.fund_in")
      expect(find("label#player_name").text).to eq @player.player_name
      expect(find("label#player_member_id").text).to eq @player.member_id.to_s
      check_flash_message I18n.t("invalid_amt.deposit")
    end



  end
end
