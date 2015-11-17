require "feature_spec_helper"

describe FundController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[48] Pending Transaction' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      mock_close_after_print
      mock_have_active_location
      mock_patron_not_change
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => "123456", :card_id => "1234567890", :currency_id => 1, :status => "active")

      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0)
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Base).to receive(:send).and_return({:error_code => 'not OK'})
      allow_any_instance_of(Requester::Wallet).to receive(:remote_response_checking).and_raise(Exception.new)
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => "1234567890", :member_id => "123456", :blacklist => false, :pin_status => 'used' })
    end
    
    after(:each) do
      clean_dbs
    end
    
    def create_player_transaction
      @machine_token1 = '20000|1|LOCATION1|1|STATION1|1|machine1|6e80a295eeff4554bf025098cca6eb37'
      @player_transaction1 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "pending", :amount => 10000, :machine_token => @machine_token1, :created_at => Time.now, :slip_number => 1)
    end

    it '[48.1] Pending Deposit Transaction', :js => true do
      login_as_admin
      go_to_deposit_page
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_call_original
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return('no_balance')
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_fund_in").click
      find("div#pop_up_dialog div button#confirm").click
      wait_for_ajax

      player_transaction = PlayerTransaction.find_by_player_id(@player.id)
      expect(player_transaction.status).to eq 'pending'
      check_balance_page_without_balance
      check_player_lock_types
      @player.reload
      expect(@player.lock_types.include?('pending')).to eq true
      expect(@player.status).to eq 'locked'
      check_flash_message I18n.t('flash_message.contact_service')
      expect(find("div a#balance_deposit")[:disabled]).to eq 'disabled'
      expect(find("div a#balance_withdraw")[:disabled]).to eq 'disabled'
    end

    it '[48.2] Show (Pending) status in Player Profile ', :js => true do
      @player.unlock_account!('pending')
      login_as_admin
      go_to_balance_enquiry_page
      check_player_lock_types
    end

    it '[48.3] Show Pending transcaction in transcation history', :js => true do
      login_as_admin
      create_player_transaction
      visit search_transactions_path 
      check_player_transaction_page_js

      fill_in "slip_number", :with => @player_transaction1.slip_number
      find("input#selected_tab_index").set "1"

      find("input#search").click
      wait_for_ajax
      check_player_transaction_result_items([@player_transaction1])
    end

    it '[48.4] invalid Withdraw (invalid balance)', :js => true do
      allow_any_instance_of(Requester::Wallet).to receive(:withdraw).and_raise(Remote::AmountNotEnough, "0.0")
      login_as_admin 
      mock_have_active_location
      go_to_withdraw_page
      fill_in "player_transaction_amount", :with => 300
      find("button#confirm_fund_out").click
      find("div#pop_up_dialog")[:style].include?("block").should == true
      find("div#pop_up_dialog div button#confirm").click
      check_title("tree_panel.fund_out")
      expect(find("label#player_full_name").text).to eq @player.full_name.upcase
      expect(find("label#player_member_id").text).to eq @player.member_id.to_s
      check_flash_message I18n.t("invalid_amt.no_enough_to_withdraw", { balance: to_display_amount_str(@player_balance)})
      player_transaction = PlayerTransaction.find_by_player_id(@player.id)
      expect(player_transaction.status).to eq 'rejected'
    end

    it '[48.5] Pending Withdraw Transaction', :js => true do
      login_as_admin
      go_to_withdraw_page
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_call_original
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return('no_balance')
      fill_in "player_transaction_amount", :with => 100
      find("button#confirm_fund_out").click
      find("div#pop_up_dialog div button#confirm").click
      wait_for_ajax

      player_transaction = PlayerTransaction.find_by_player_id(@player.id)
      expect(player_transaction.status).to eq 'pending'
      check_balance_page_without_balance
      check_player_lock_types
      @player.reload
      expect(@player.lock_types.include?('pending')).to eq true
      expect(@player.status).to eq 'locked'
      expect(find("div a#balance_deposit")[:disabled]).to eq 'disabled'
      expect(find("div a#balance_withdraw")[:disabled]).to eq 'disabled'
    end
  end
end
