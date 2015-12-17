require "feature_spec_helper"

describe CreditExpireController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[61] Expire credit' do
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

    it '[61.1] Expire credit success', :js => true do
      allow_any_instance_of(Requester::Wallet).to receive(:credit_expire).and_return('OK')
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return({:balance => 0.00, :credit_balance => 50.00, :credit_expired_at => Time.now})
      login_as_admin 
      go_to_credit_expire_page
      fill_in "player_transaction_remark", :with => 'test'
      content_list = [I18n.t("deposit_withdrawal.credit_expire_amt")]
      click_pop_up_confirm("confirm_credit_expire", content_list)
      wait_for_ajax
      credit_transaction = PlayerTransaction.find_by_player_id(@player.id)
      check_credit_transaction(credit_transaction, 'credit_expire', 'completed', 5000, 'test')

      check_balance_page
      check_flash_message I18n.t("flash_message.credit_expire_complete", amount: to_display_amount_str(credit_transaction.amount))
    end

    it '[61.2] Expire credit fail with no enough credit balance', :js => true do
      allow_any_instance_of(Requester::Wallet).to receive(:credit_expire).and_raise(Remote::AmountNotMatch.new("0.0"))
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return({:balance => 0.00, :credit_balance => 50.00, :credit_expired_at => Time.now})
      login_as_admin 
      go_to_credit_expire_page
      fill_in "player_transaction_remark", :with => 'test'
      content_list = [I18n.t("deposit_withdrawal.credit_expire_amt")]
      click_pop_up_confirm("confirm_credit_expire", content_list)
      wait_for_ajax
      check_balance_page
      check_flash_message I18n.t("invalid_amt.no_enough_to_credit_expire", { balance: to_display_amount_str(0)})
    end

    it '[61.3] Expire credit fail with disconnection with wallet', :js => true do
      allow_any_instance_of(Requester::Wallet).to receive(:credit_expire).and_return('not OK')
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return({:balance => 0.00, :credit_balance => 50.00, :credit_expired_at => Time.now})
      login_as_admin 
      go_to_credit_expire_page
      fill_in "player_transaction_remark", :with => 'test'
      content_list = [I18n.t("deposit_withdrawal.credit_expire_amt")]
      click_pop_up_confirm("confirm_credit_expire", content_list)
      wait_for_ajax
      credit_transaction = PlayerTransaction.find_by_player_id(@player.id)
      check_credit_transaction(credit_transaction, 'credit_expire', 'pending', 5000, 'test')
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
