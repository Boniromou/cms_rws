require "feature_spec_helper"

describe CreditDepositController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[60] Add credit' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      mock_close_after_print
      mock_patron_not_change
      mock_have_active_location
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => "123456", :card_id => "1234567890", :currency_id => 2, :status => "active", :property_id => 20000)

      mock_wallet_balance(0.0)
    end
    
    after(:each) do
      clean_dbs
    end

    it '[60.1] Add credit success', :js => true do
      mock_wallet_transaction_success(:credit_deposit)
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return({:balance => 0.00, :credit_balance => 0.00, :credit_expired_at => Time.now})
      login_as_admin
      go_to_credit_deposit_page
      fill_in "player_transaction_amount", :with => 100
      fill_in "player_transaction_remark", :with => 'test'
      content_list = [I18n.t("deposit_withdrawal.credit_deposit_amt")]
      click_pop_up_confirm("confirm_credit_deposit", content_list)
      wait_for_ajax

      credit_transaction = PlayerTransaction.find_by_player_id(@player.id)
      check_credit_transaction(credit_transaction, 'credit_deposit', 'completed', 10000, 'test')
      
      check_flash_message I18n.t("flash_message.credit_deposit_complete", amount: to_display_amount_str(credit_transaction.amount))
    end

    it '[60.2] Add credit fail with credit already added', :js => true do
      allow_any_instance_of(Requester::Wallet).to receive(:credit_deposit).and_raise(Remote::CreditNotExpired)
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return({:balance => 0.00, :credit_balance => 0.00, :credit_expired_at => Time.now})
      login_as_admin 
      go_to_credit_deposit_page
      fill_in "player_transaction_amount", :with => 100
      fill_in "player_transaction_remark", :with => 'test'
      content_list = [I18n.t("deposit_withdrawal.credit_deposit_amt")]
      click_pop_up_confirm("confirm_credit_deposit", content_list)
      wait_for_ajax

      check_balance_page
      check_flash_message I18n.t("invalid_amt.credit_exist")
    end

    it '[60.3] Add credit fail with disconnection with wallet', :js => true do
      allow_any_instance_of(Requester::Wallet).to receive(:credit_deposit).and_return(Requester::WalletTransactionResponse.new({:error_code => 'not OK'}))
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return({:balance => 0.00, :credit_balance => 0.00, :credit_expired_at => Time.now})
      login_as_admin 
      go_to_credit_deposit_page
      fill_in "player_transaction_amount", :with => 100
      fill_in "player_transaction_remark", :with => 'test'
      content_list = [I18n.t("deposit_withdrawal.credit_deposit_amt")]
      click_pop_up_confirm("confirm_credit_deposit", content_list)
      wait_for_ajax

      credit_transaction = PlayerTransaction.find_by_player_id(@player.id)
      check_credit_transaction(credit_transaction, 'credit_deposit', 'pending', 10000, 'test')
      
      check_player_lock_types
      @player.reload
      expect(@player.status).to eq 'locked'
      check_flash_message I18n.t('flash_message.contact_service')
      expect(find("div a#balance_deposit")[:disabled]).to eq 'disabled'
      expect(find("div a#balance_withdraw")[:disabled]).to eq 'disabled'
      expect(find("div a#credit_deposit")[:disabled]).to eq 'disabled'
      expect(find("div a#credit_expire")[:disabled]).to eq 'disabled'
    end
  end
end
