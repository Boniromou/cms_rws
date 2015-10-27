require "feature_spec_helper"

describe VoidController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  
  describe '[47] Void Transaction' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      mock_close_after_print
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => "123456", :card_id => "1234567890", :currency_id => 1, :status => "active")

      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(0.0)
    end
    
    after(:each) do
      clean_dbs
    end
    
    def create_player_transaction
      @location6 = Location.create!(:name => "LOCATION6", :status => "active")
      @station6 = Station.create!(:name => "STATION6", :status => "active", :location_id => @location6.id)
      @player_transaction1 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 10000, :station_id => @station6.id, :created_at => Time.now)
    end

    it '[47.1] Display void button', :js => true do
      create_past_shift
      login_as_admin
      @location6 = Location.create!(:name => "LOCATION6", :status => "active")
      @station6 = Station.create!(:name => "STATION6", :status => "active", :location_id => @location6.id)
      @player_transaction2 = PlayerTransaction.create!(:shift_id => @past_shift.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 10000, :station_id => @station6.id, :created_at => Time.now)
      @player_transaction1 = PlayerTransaction.create!(:shift_id => Shift.last.id, :player_id => @player.id, :user_id => User.first.id, :transaction_type_id => 1, :status => "completed", :amount => 10000, :station_id => @station6.id, :created_at => Time.now)
      visit search_transactions_path 
      check_player_transaction_page_js

      fill_in "start", :with => @player_transaction2.shift.accounting_date.to_s
      fill_in "end", :with => @player_transaction1.shift.accounting_date.to_s
      fill_in "id_number", :with => @player_transaction1.player.card_id
      find("input#selected_tab_index").set "0"

      find("input#search").click
      wait_for_ajax
      check_player_transaction_result_items([@player_transaction2,@player_transaction1])
    end
    
    it '[47.2] Void success', :js => true do
      allow_any_instance_of(Requester::Standard).to receive(:void_deposit).and_return('OK')
      login_as_admin
      create_player_transaction
      visit search_transactions_path 
      check_player_transaction_page_js

      fill_in "transaction_id", :with => @player_transaction1.id
      find("input#selected_tab_index").set "1"

      find("input#search").click
      wait_for_ajax
      check_player_transaction_result_items([@player_transaction1])
      
      content_list = [I18n.t("confirm_box.void_transaction", slip_number: @player_transaction1.slip_number.to_s)]
      click_pop_up_confirm("void_deposit_" + @player_transaction1.id.to_s, content_list)

      check_flash_message I18n.t("void_transaction.success", slip_number: @player_transaction1.slip_number.to_s)
      @player_transaction1.reload
      check_player_transaction_result_items([@player_transaction1])
      void_transaction = PlayerTransaction.where(:player_id => @player.id, :transaction_type_id => 3).first
      expect(void_transaction.status).to eq 'completed'
      expect(page.source).to have_selector("iframe")
    end

    it '[47.3] disconnection Void depopsit fail', :js => true do
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Base).to receive(:send).and_return({:error_code => 'not OK'})
      allow_any_instance_of(Requester::Standard).to receive(:remote_response_checking).and_raise(Exception.new)
      login_as_admin
      create_player_transaction
      visit search_transactions_path 
      check_player_transaction_page_js

      fill_in "transaction_id", :with => @player_transaction1.id
      find("input#selected_tab_index").set "1"

      find("input#search").click
      wait_for_ajax
      check_player_transaction_result_items([@player_transaction1])
      
      content_list = [I18n.t("confirm_box.void_transaction", slip_number: @player_transaction1.slip_number.to_s)]
      click_pop_up_confirm("void_deposit_" + @player_transaction1.id.to_s, content_list)
      
      check_flash_message I18n.t("flash_message.contact_service")
      wait_for_ajax
      @player_transaction1.reload
      check_player_transaction_result_items([@player_transaction1])
      void_transaction = PlayerTransaction.where(:player_id => @player.id, :transaction_type_id => 3).first
      expect(void_transaction.status).to eq 'pending'
      @player.reload
      expect(@player.lock_types.include?('pending')).to eq true
      expect(@player.status).to eq 'locked'
    end

    it '[47.4] disconnection Void withdraw fail', :js => true do
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Base).to receive(:send).and_return({:error_code => 'not OK'})
      allow_any_instance_of(Requester::Standard).to receive(:remote_response_checking).and_raise(Exception.new)
      login_as_admin
      create_player_transaction
      @player_transaction1.transaction_type_id = 2
      @player_transaction1.save
      visit search_transactions_path 
      check_player_transaction_page_js

      fill_in "transaction_id", :with => @player_transaction1.id
      find("input#selected_tab_index").set "1"

      find("input#search").click
      wait_for_ajax
      check_player_transaction_result_items([@player_transaction1])
      
      content_list = [I18n.t("confirm_box.void_transaction", slip_number: @player_transaction1.slip_number.to_s)]
      click_pop_up_confirm("void_withdraw_" + @player_transaction1.id.to_s, content_list)
      
      check_flash_message I18n.t("flash_message.contact_service")
      @player_transaction1.reload
      check_player_transaction_result_items([@player_transaction1])
      void_transaction = PlayerTransaction.where(:player_id => @player.id, :transaction_type_id => 4).first
      expect(void_transaction.status).to eq 'pending'
      @player.reload
      expect(@player.lock_types.include?('pending')).to eq true
      expect(@player.status).to eq 'locked'
    end

    it '[47.5] balance not enough to void deposit', :js => true do
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Base).to receive(:send).and_return({:error_code => "AmountNotEnough"})
      allow_any_instance_of(Requester::Standard).to receive(:remote_response_checking).and_return({:error_code => "AmountNotEnough"})
      login_as_admin
      create_player_transaction
      visit search_transactions_path 
      check_player_transaction_page_js

      fill_in "transaction_id", :with => @player_transaction1.id
      find("input#selected_tab_index").set "1"

      find("input#search").click
      wait_for_ajax
      check_player_transaction_result_items([@player_transaction1])
      
      content_list = [I18n.t("confirm_box.void_transaction", slip_number: @player_transaction1.slip_number.to_s)]
      click_pop_up_confirm("void_deposit_" + @player_transaction1.id.to_s, content_list)
      
      check_flash_message I18n.t("invalid_amt.no_enough_to_void_deposit", { balance: to_display_amount_str(@player_balance)})
      @player_transaction1.reload
      check_player_transaction_result_items([@player_transaction1])
      void_transaction = PlayerTransaction.where(:player_id => @player.id, :transaction_type_id => 3).first
      expect(void_transaction.status).to eq 'rejected'
      @player.reload
      expect(@player.lock_types.include?('pending')).to eq false
      expect(@player.status).to eq 'active'
    end

    it '[47.6] User without void permission', :js => true do
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player_transaction,['search'])
      create_player_transaction
      visit search_transactions_path 
      check_player_transaction_page_js

      fill_in "transaction_id", :with => @player_transaction1.id
      find("input#selected_tab_index").set "1"

      find("input#search").click
      wait_for_ajax
      check_player_transaction_result_items([@player_transaction1],false,false,false)
    end
  end

end
