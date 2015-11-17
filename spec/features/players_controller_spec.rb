require "feature_spec_helper"

describe PlayersController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
    PlayerTransaction.delete_all
  end

  after(:all) do
    PlayerTransaction.delete_all
    User.delete_all
    Warden.test_reset!
  end

  describe '[3] Create player' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info

      allow_any_instance_of(Requester::Wallet).to receive(:create_player).and_return('OK')
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0.0)
    end

    after(:each) do
      clean_dbs
    end

    it '[3.1] Show Create Player Page' do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.create_player")
      check_title("tree_panel.create_player")
      expect(page.source).to have_selector("form#new_player input#player_member_id")
      expect(page.source).to have_selector("form#new_player input#player_card_id")
      expect(page.source).to have_selector("form#new_player input#player_first_name")
      expect(page.source).to have_selector("form#new_player input#player_last_name")
    end

    it '[3.2] Successfully create player' do
      login_as_admin
      visit new_player_path
      @player = Player.new
      @player.card_id = 1234567890
      @player.member_id = 123456
      @player.first_name = "test"
      @player.last_name = "player"
      fill_in "player_card_id", :with => @player.card_id
      fill_in "player_member_id", :with => @player.member_id
      fill_in "player_first_name", :with => @player.first_name
      fill_in "player_last_name", :with => @player.last_name
      click_button I18n.t("button.create")

      check_title("tree_panel.balance")
      check_flash_message I18n.t("create_player.success", first_name: @player.first_name.upcase, last_name: @player.last_name.upcase)

      test_player = Player.find_by_member_id(@player.member_id)
      expect(test_player).not_to be_nil
      test_player.card_id = @player.card_id
      test_player.member_id = @player.member_id
      test_player.first_name = @player.first_name
      test_player.last_name = @player.last_name
    end

    it '[3.3] player already exist (member ID)' do
      Player.create!(:first_name => "exist1", :last_name => "exist2", :member_id => '123456', :currency_id => 1, :status => "active")
      login_as_admin
      visit new_player_path
      @player = Player.new
      @player.card_id = 1234567890
      @player.member_id = 123456
      @player.first_name = "test"
      @player.last_name = "player"
      fill_in "player_card_id", :with => @player.card_id
      fill_in "player_member_id", :with => @player.member_id
      fill_in "player_first_name", :with => @player.first_name
      fill_in "player_last_name", :with => @player.last_name
      click_button I18n.t("button.create")

      check_title("tree_panel.create_player")
      check_flash_message I18n.t("create_player.member_id_exist", member_id: @player.member_id)
    end

    it '[3.4] empty membership ID' do
      login_as_admin
      visit new_player_path
      @player = Player.new
      @player.card_id = 1234567890
      @player.member_id = 123456
      @player.first_name = "test"
      @player.last_name = "player"
      fill_in "player_card_id", :with => @player.card_id
      fill_in "player_first_name", :with => @player.first_name
      fill_in "player_last_name", :with => @player.last_name
      click_button I18n.t("button.create")

      check_title("tree_panel.create_player")
      check_flash_message I18n.t("create_player.member_id_length_error")
    end

    it '[3.5] empty Player first name' do
      login_as_admin
      visit new_player_path
      @player = Player.new
      @player.card_id = 1234567890
      @player.member_id = 123456
      @player.first_name = "test"
      @player.last_name = "player"
      fill_in "player_card_id", :with => @player.card_id
      fill_in "player_member_id", :with => @player.member_id
      fill_in "player_last_name", :with => @player.last_name
      click_button I18n.t("button.create")

      check_title("tree_panel.create_player")
      check_flash_message I18n.t("create_player.first_name_blank_error")
    end

    it '[3.6] Audit log for successful create player' do
      login_as_admin
      visit new_player_path
      @player = Player.new
      @player.card_id = 1234567890
      @player.member_id = 123456
      @player.first_name = "test"
      @player.last_name = "player"
      fill_in "player_card_id", :with => @player.card_id
      fill_in "player_member_id", :with => @player.member_id
      fill_in "player_first_name", :with => @player.first_name
      fill_in "player_last_name", :with => @player.last_name
      click_button I18n.t("button.create")

      audit_log = AuditLog.find_by_audit_target("player")
      audit_log.should_not be_nil
      audit_log.audit_target.should == "player"
      audit_log.action_by.should == @root_user.name
      audit_log.action_type.should == "create"
      audit_log.action.should == "create"
      audit_log.action_status.should == "success"
      audit_log.action_error.should be_nil
      audit_log.ip.should_not be_nil
      audit_log.session_id.should_not be_nil
      audit_log.description.should_not be_nil
    end

    it '[3.7] Audit log for fail create player' do
      Player.create!(:first_name => "exist", :last_name => "player", :member_id => '123456', :currency_id => 1, :status => "active")
      login_as_admin
      visit new_player_path
      @player = Player.new
      @player.card_id = 1234567890
      @player.member_id = 123456
      @player.first_name = "test"
      @player.last_name = "player"
      fill_in "player_card_id", :with => @player.card_id
      fill_in "player_member_id", :with => @player.member_id
      fill_in "player_first_name", :with => @player.first_name
      fill_in "player_last_name", :with => @player.last_name
      click_button I18n.t("button.create")

      audit_log = AuditLog.find_by_audit_target("player")
      audit_log.should_not be_nil
      audit_log.audit_target.should == "player"
      audit_log.action_by.should == @root_user.name
      audit_log.action_type.should == "create"
      audit_log.action.should == "create"
      audit_log.action_status.should == "fail"
      audit_log.action_error.should_not be_nil
      audit_log.ip.should_not be_nil
      audit_log.session_id.should_not be_nil
      audit_log.description.should_not be_nil
    end

    it '[3.8] click unauthorized action', js: true do 
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["create"])
      visit home_path
      set_permission(@test_user,"cashier",:player,[])
      click_link I18n.t("tree_panel.create_player")
      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end     
    
    it '[3.9] click link to the unauthorized page', js: true do 
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,[])
      visit new_player_path
      wait_for_ajax
      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end     
    
    it '[3.10] unauthorization for create player', js: true do 
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,[])
      visit home_path
      first("aside#left-panel ul li#nav_create_player").should be_nil
    end     

    it '[3.11] empty card ID' do
      login_as_admin
      visit new_player_path
      @player = Player.new
      @player.card_id = 1234567890
      @player.member_id = 123456
      @player.first_name = "test"
      @player.last_name = "player"
      fill_in "player_member_id", :with => @player.member_id
      fill_in "player_first_name", :with => @player.first_name
      fill_in "player_last_name", :with => @player.last_name
      click_button I18n.t("button.create")

      check_title("tree_panel.create_player")
      check_flash_message I18n.t("create_player.card_id_length_error")
    end

    it '[3.12] member id and card ID can only input number' do
      login_as_admin
      visit new_player_path
      fill_in "player_card_id", :with => '..//.-=-++-'
      fill_in "player_member_id", :with => '123456'
      fill_in "player_first_name", :with => '$$$$'
      fill_in "player_last_name", :with => '@@@@'
      click_button I18n.t("button.create")

      check_title("tree_panel.create_player")
      check_flash_message I18n.t("create_player.card_id_only_number_allowed_error")
      
      fill_in "player_card_id", :with => '1234567890'
      fill_in "player_member_id", :with => 'hahaha'
      fill_in "player_first_name", :with => '$$$$'
      fill_in "player_last_name", :with => '@@@@'
      click_button I18n.t("button.create")

      check_title("tree_panel.create_player")
      check_flash_message I18n.t("create_player.member_id_only_number_allowed_error")
    end

    it '[3.13] player already exist (card ID)' do
      Player.create!(:first_name => "exist", :last_name => "player", :card_id => '1234567890', :currency_id => 1, :status => "active")
      login_as_admin
      visit new_player_path
      @player = Player.new
      @player.card_id = 1234567890
      @player.member_id = 123456
      @player.first_name = "test"
      @player.last_name = "player"
      fill_in "player_card_id", :with => @player.card_id
      fill_in "player_member_id", :with => @player.member_id
      fill_in "player_first_name", :with => @player.first_name
      fill_in "player_last_name", :with => @player.last_name
      click_button I18n.t("button.create")

      check_title("tree_panel.create_player")
      check_flash_message I18n.t("create_player.card_id_exist", card_id: @player.card_id)
    end

    it '[3.14] empty Player last name' do
      login_as_admin
      visit new_player_path
      @player = Player.new
      @player.card_id = 1234567890
      @player.member_id = 123456
      @player.first_name = "test"
      @player.last_name = "player"
      fill_in "player_card_id", :with => @player.card_id
      fill_in "player_member_id", :with => @player.member_id
      fill_in "player_first_name", :with => @player.first_name
      click_button I18n.t("button.create")

      check_title("tree_panel.create_player")
      check_flash_message I18n.t("create_player.last_name_blank_error")
    end
  end
  
  describe '[4] Search player by membership ID' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info

      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0.0)
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => '1234567890', :member_id => '123456', :blacklist => false, :pin_status => 'used'})
    end

    after(:each) do
      clean_dbs
    end

    it '[4.1] Show search Page' do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.balance")
      check_search_page
    end

    it '[4.2] successfully search player' do
      @player = Player.create!(:first_name => "exist", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")
      login_as_admin
      visit players_search_path + "?operation=balance"
      fill_search_info("member_id", @player.member_id)
      find("#button_find").click
      check_balance_page
      check_player_info
    end
    
    it '[4.3] fail to search player' do
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_raise(Remote::PlayerNotFound)
      @player = Player.new
      @player.member_id = 12345
      @player.first_name = "test"
      @player.last_name = "player"
      login_as_admin
      visit players_search_path + "?operation=balance"
      fill_search_info("member_id", @player.member_id)
      find("#button_find").click
      check_not_found
      click_link I18n.t("button.create")
    end
    
    it '[4.4] direct to create player' do
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_raise(Remote::PlayerNotFound)
      @player = Player.new
      @player.member_id = 12345
      @player.first_name = "test"
      @player.last_name = "player"
      login_as_admin
      visit players_search_path + "?operation=balance"
      fill_search_info("member_id", @player.member_id)
      find("#button_find").click
      check_not_found
      find("div#message_content a.btn").click
      check_title("tree_panel.create_player")
      expect(find("form#new_player input#player_member_id").value).to eq @player.member_id.to_s
    end
  end
  
  describe '[5] Balance Enquiry' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info

      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0.0)
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => '1234567890', :member_id => '123456', :blacklist => false, :pin_status => 'used'})
    end

    after(:each) do
      clean_dbs
    end

    it '[5.1] view player balance enquiry', :js => true do
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(99.99)

      @player = Player.create!(:first_name => "exist", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")
      login_as_admin

      mock_have_enable_station

      visit home_path
      click_link I18n.t("tree_panel.balance")
      wait_for_ajax
      check_search_page
      fill_search_info_js("member_id", @player.member_id)
      find("#button_find").click
      
      check_player_info
      check_balance_page(9999)

      expect(page.source).to have_selector("div a#balance_deposit")
      expect(page.source).to have_selector("div a#balance_withdraw")
      expect(find("div a#balance_deposit")[:disabled]).to eq nil
      expect(find("div a#balance_withdraw")[:disabled]).to eq nil

    end

    it '[5.2] click unauthorized action', :js => true do 
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["balance"])
      visit home_path
      set_permission(@test_user,"cashier",:player,[])
      click_link I18n.t("tree_panel.balance")
      wait_for_ajax
      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end     
    
    it '[5.3] click link to the unauthorized page', :js => true do 
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,[])
      visit balance_path
      wait_for_ajax
      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end     
    
    it '[5.4] authorized to search and unauthorized to create' do 
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_raise(Remote::PlayerNotFound)
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["balance"])
      visit players_search_path + "?operation=balance"
      fill_search_info("member_id", 123456)

      find("#button_find").click
      check_not_found
      expect(page.source).to_not have_content(I18n.t("search_error.create_player"))
    end     
    
    it '[5.5] Return to Cage home', :js => true do
      login_as_admin

      visit home_path
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(99.99)
      mock_have_enable_station

      @player = Player.create!(:first_name => "exist", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")
      click_link I18n.t("tree_panel.balance")
      wait_for_ajax
      check_search_page
      fill_search_info_js("member_id", @player.member_id)
      find("#button_find").click
      
      check_balance_page(9999)
      check_player_info
      
      expect(page.source).to have_selector("div a#balance_deposit")
      expect(page.source).to have_selector("div a#balance_withdraw")

      click_link I18n.t("tree_panel.home")
      check_home_page
    end

    it '[5.6] unauthorized to all actions' do
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(99.99)

      @player = Player.create!(:first_name => "exist", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["balance"])
      set_permission(@test_user,"cashier",:player_transaction,[])
      visit home_path
      click_link I18n.t("tree_panel.balance")
      check_search_page
      fill_search_info("member_id", @player.member_id)
      find("#button_find").click

      check_balance_page(9999)
      check_player_info
      
      expect(page.source).to_not have_selector("div a#balance_deposit")
      expect(page.source).to_not have_selector("div a#balance_withdraw")
    end
    
    it '[5.7] unathorized to balance enquriy ' do 
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,[])
      visit home_path
      first("aside#left-panel ul li#nav_balance_enquiry").should be_nil
    end     

    it '[5.8] balance enquiry with locked player', :js => true do
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(99.99)
      mock_have_enable_station
      
      @player = Player.create!(:first_name => "exist", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "locked")
      @player.lock_account!
      login_as_admin

      visit home_path
      click_link I18n.t("tree_panel.balance")
      wait_for_ajax
      check_search_page
      fill_search_info_js("member_id", @player.member_id)
      find("#button_find").click
      
      check_player_info
      check_balance_page(9999)

      expect(page).to have_selector("div a#balance_deposit")
      expect(page).to have_selector("div a#balance_withdraw")
      expect(find("div a#balance_deposit")[:disabled]).to eq 'disabled'
      expect(find("div a#balance_withdraw")[:disabled]).to eq 'disabled'
    end
  end
  
  describe '[12] Search player by card ID' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info

      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0.0)
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => '1234567890', :member_id => '123456', :blacklist => false, :pin_status => 'used'})
    end

    after(:each) do
      clean_dbs
    end

    it '[12.1] Show search Page' do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.balance")
      check_search_page
    end

    it '[12.2] successfully search player' do
      @player = Player.create!(:first_name => "exist", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")
      login_as_admin
      visit players_search_path + "?operation=balance"
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_balance_page
      check_player_info
    end
    
    it '[12.3] fail to search player' do
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_raise(Remote::PlayerNotFound)
      @player = Player.new
      @player.member_id = 123456
      @player.card_id = 1234567890
      @player.first_name = "test"
      @player.last_name = "player"
      login_as_admin
      visit players_search_path + "?operation=balance"
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_not_found
      click_link I18n.t("button.create")
    end
    
    it '[12.4] direct to create player' do
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_raise(Remote::PlayerNotFound)
      @player = Player.new
      @player.member_id = 123456
      @player.card_id = 1234567890
      @player.first_name = "test"
      @player.last_name = "player"
      login_as_admin
      visit players_search_path + "?operation=balance"
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_not_found
      find("div#message_content a.btn").click
      check_title("tree_panel.create_player")
      expect(find("form#new_player input#player_card_id").value).to eq @player.card_id.to_s
    end
  end
  
  describe '[15] Lock/Unlock Player' do
    def update_lock_or_unlock
      if @player.status == 'active'
        @lock_or_unlock = "lock"
      else
        @lock_or_unlock = "unlock"
      end
    end

    def check_lock_unlock_components
      expect(page).to have_selector "div#pop_up_dialog"
      expect(find("div#pop_up_dialog")[:style]).to include "none"
    end

    def check_lock_unlock_page
      @player.reload
      update_lock_or_unlock

      check_profile_page
      check_player_info
      check_lock_unlock_components
    end

    def search_player_profile
      fill_search_info_js("card_id", @player.card_id)
      find("#button_find").click
      wait_for_ajax
    end

    def toggle_player_lock_status_and_check
      check_lock_unlock_page

      click_button I18n.t("button.#{@lock_or_unlock}")
      expect(find("div#pop_up_dialog")[:style]).to_not include "none"

      expected_flash_message = I18n.t("#{@lock_or_unlock}_player.success", name: @player.full_name.upcase)

      click_button I18n.t("button.confirm")
      wait_for_ajax

      check_lock_unlock_page
      check_flash_message expected_flash_message
    end

    def lock_or_unlock_player_and_check
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.profile")
      wait_for_ajax

      check_search_page("profile")

      search_player_profile
      toggle_player_lock_status_and_check
    end

    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info

      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")

      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0.0)
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => '1234567890', :member_id => '123456', :blacklist => false, :pin_status => 'used'})
    end

    after(:each) do
      clean_dbs
    end

    it '[15.1] Successfully Lock player', js: true do
      lock_or_unlock_player_and_check
    end 

    it '[15.2] Successfully unlock player', js: true do
      @player.status = "locked"
      @player.save
      @players_lock_type = PlayersLockType.add_lock_to_player(@player.id,'cage_lock')

      lock_or_unlock_player_and_check
    end 

    it '[15.3] unauthorized to lock/unlock' do 
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["profile"])
      visit home_path
      click_link I18n.t("tree_panel.profile")

      expect(page).to_not have_button I18n.t("button.lock")
      expect(page).to_not have_button I18n.t("button.unlock")
      expect(page).to_not have_selector "div#confirm_lock_player_dialog"
      expect(page).to_not have_selector "div#confirm_unlock_player_dialog"
    end

    it '[15.4] Audit log for lock player', js: true do
      lock_or_unlock_player_and_check

      audit_log = AuditLog.find_by_audit_target("player")
      expect(audit_log).to_not be_nil
      expect(audit_log.audit_target).to eq "player"
      expect(audit_log.action_by).to eq @root_user.name
      expect(audit_log.action_type).to eq "update"
      expect(audit_log.action).to eq "lock"
      expect(audit_log.action_status).to eq "success"
      expect(audit_log.action_error).to be_nil
      expect(audit_log.ip).to_not be_nil
      expect(audit_log.session_id).to_not be_nil
      expect(audit_log.description).to_not be_nil
    end

    it '[15.5] audit log for unlock player', js: true do
      @player.status = "locked"
      @player.save
      @players_lock_type = PlayersLockType.add_lock_to_player(@player.id,'cage_lock')

      lock_or_unlock_player_and_check

      audit_log = AuditLog.find_by_audit_target("player")
      expect(audit_log).to_not be_nil
      expect(audit_log.audit_target).to eq "player"
      expect(audit_log.action_by).to eq @root_user.name
      expect(audit_log.action_type).to eq "update"
      expect(audit_log.action).to eq "unlock"
      expect(audit_log.action_status).to eq "success"
      expect(audit_log.action_error).to be_nil
      expect(audit_log.ip).to_not be_nil
      expect(audit_log.session_id).to_not be_nil
      expect(audit_log.description).to_not be_nil
    end

    it '[15.6] Show cage lock and Blacklist player status ', js: true do
      @player.status = "locked"
      @player.save
      @players_lock_type = PlayersLockType.add_lock_to_player(@player.id,'cage_lock')
      @players_lock_type = PlayersLockType.add_lock_to_player(@player.id,'blacklist')

      lock_or_unlock_player_and_check
    end 

  end

  describe '[36] Expire token' do
     before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0.0)
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => '1234567890', :member_id => '123456', :blacklist => false, :pin_status => 'used'})
      @player = Player.create!(:id => 10, :first_name => "test", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")
      @token1 = Token.create!(:session_token => 'abm39492i9jd9wjn', :player_id => 10, :expired_at => Time.now + 1800)
      @token2 = Token.create!(:session_token => '3949245469jd9wjn', :player_id => 10, :expired_at => Time.now + 1800)
    end

     after(:each) do
      Token.delete_all
      clean_dbs
    end

    it '[36.1] Expire token when player is locked from cage', js: true do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.profile")
      wait_for_ajax

      check_search_page("profile")

      fill_search_info_js("card_id", @player.card_id)
      find("#button_find").click
      wait_for_ajax

      @player.reload

      if @player.status == 'active'
        @lock_or_unlock = "lock"
      else
        @lock_or_unlock = "unlock"
      end

      check_profile_page
      check_player_info

      expect(page).to have_selector "div#pop_up_dialog"
      expect(find("div#pop_up_dialog")[:style]).to include "none"

      click_button I18n.t("button.#{@lock_or_unlock}")
      expect(find("div#pop_up_dialog")[:style]).to_not include "none"

      expected_flash_message = I18n.t("#{@lock_or_unlock}_player.success", name: @player.full_name.upcase)

      click_button I18n.t("button.confirm")
      wait_for_ajax

      @player.reload

      if @player.status == 'active'
        @lock_or_unlock = "lock"
      else
        @lock_or_unlock = "unlock"
      end

      check_profile_page
      check_player_info

      expect(page).to have_selector "div#pop_up_dialog"
      expect(find("div#pop_up_dialog")[:style]).to include "none"

      check_flash_message expected_flash_message
      token_test1 = Token.find_by_session_token('abm39492i9jd9wjn')
      token_test2 = Token.find_by_session_token('3949245469jd9wjn')
      token_test1.expired_at.strftime("%Y-%m-%d %H:%M:%S UTC").should >= (Time.now.utc - 200).strftime("%Y-%m-%d %H:%M:%S UTC")
      token_test1.expired_at.strftime("%Y-%m-%d %H:%M:%S UTC").should <= (Time.now.utc + 200).strftime("%Y-%m-%d %H:%M:%S UTC")
      token_test2.expired_at.strftime("%Y-%m-%d %H:%M:%S UTC").should >= (Time.now.utc - 200).strftime("%Y-%m-%d %H:%M:%S UTC")
      token_test2.expired_at.strftime("%Y-%m-%d %H:%M:%S UTC").should <= (Time.now.utc + 200).strftime("%Y-%m-%d %H:%M:%S UTC")
    end
  end
  
  describe '[37] Show balance not found' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => '1234567890', :member_id => '123456', :blacklist => false, :pin_status => 'used'})

    end

    after(:each) do
      clean_dbs
    end

    it '[37.1] Player balance not found', :js => true do
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return('no_balance')

      @player = Player.create!(:first_name => "exist", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")
      login_as_admin

      mock_have_enable_station

      visit home_path
      click_link I18n.t("tree_panel.balance")
      wait_for_ajax
      check_search_page
      fill_search_info_js("member_id", @player.member_id)
      find("#button_find").click
      
      check_player_info
      check_balance_page_without_balance

      expect(page.source).to have_selector("div a#balance_deposit")
      expect(page.source).to have_selector("div a#balance_withdraw")
      expect(find("div a#balance_deposit")[:disabled]).to eq nil
      expect(find("div a#balance_withdraw")[:disabled]).to eq nil

    end
  end
  
  describe '[38] Retry create player' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => '1234567890', :member_id => '123456', :blacklist => false, :pin_status => 'used'})
      
    end

    after(:each) do
      clean_dbs
    end

    it '[38.1] Retry create player success', :js => true do
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Base).to receive(:send).and_return({:error_code => 'InvalidLoginName'},{:error_code => 'OK', :balance => 99.99})
      allow_any_instance_of(Requester::Wallet).to receive(:remote_response_checking).and_return({:error_code => 'InvalidLoginName'},{:error_code => 'OK', :balance => 99.99})
      allow_any_instance_of(Requester::Wallet).to receive(:create_player).and_return('OK')

      @player = Player.create!(:first_name => "exist", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")
      login_as_admin

      mock_have_enable_station

      visit home_path
      click_link I18n.t("tree_panel.balance")
      wait_for_ajax
      check_search_page
      fill_search_info_js("member_id", @player.member_id)
      find("#button_find").click
      
      check_player_info
      check_balance_page(9999)

      expect(page.source).to have_selector("div a#balance_deposit")
      expect(page.source).to have_selector("div a#balance_withdraw")
      expect(find("div a#balance_deposit")[:disabled]).to eq nil
      expect(find("div a#balance_withdraw")[:disabled]).to eq nil
    end

    it '[38.2] Retry create player  fail', :js => true do
      allow_any_instance_of(LaxSupport::AuthorizedRWS::Base).to receive(:send).and_return({:error_code => 'InvalidLoginName'})

      @player = Player.create!(:first_name => "exist", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")
      login_as_admin

      mock_have_enable_station

      visit home_path
      click_link I18n.t("tree_panel.balance")
      wait_for_ajax
      check_search_page
      fill_search_info_js("member_id", @player.member_id)
      find("#button_find").click
      wait_for_ajax

      check_player_info
      check_balance_page_without_balance

      expect(page.source).to have_selector("div a#balance_deposit")
      expect(page.source).to have_selector("div a#balance_withdraw")
      expect(find("div a#balance_deposit")[:disabled]).to eq nil
      expect(find("div a#balance_withdraw")[:disabled]).to eq nil
    end
  end
  
  describe '[53] Update player info when search in Balance Enquiry/Player Profile' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info

      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0.0)
    end

    after(:each) do
      clean_dbs
    end

    it '[53.1] Show PIS player info when search  Player Profile without change' do
      @player = Player.create!(:first_name => "exist", :last_name => "player", :member_id => "123456", :card_id => "1234567890", :currency_id => 1, :status => "active")
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => @player.card_id, :member_id => @player.member_id, :blacklist => @player.has_lock_type?('blacklist'), :pin_status => 'created' })
      login_as_admin
      visit players_search_path + "?operation=profile"
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_profile_page
      check_player_info
      p = Player.find(@player.id)
      expect(p.member_id).to eq @player.member_id
      expect(p.card_id).to eq @player.card_id
      expect(p.status).to eq @player.status
    end

    it '[53.2] Show PIS player info when search  Player Profile with Card ID changed' do
      @player = Player.create!(:first_name => "exist", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => '1234567891', :member_id => @player.member_id, :blacklist => @player.has_lock_type?('blacklist'), :pin_status => 'created' })
      login_as_admin
      visit players_search_path + "?operation=profile"
      fill_search_info("member_id", @player.member_id)
      find("#button_find").click
      check_profile_page
      p = Player.find(@player.id)
      expect(p.member_id).to eq @player.member_id
      expect(p.card_id).to eq '1234567891'
      expect(p.status).to eq @player.status
    end

    it '[53.3] Show PIS player info when search  Player Profile with blacklist changed' do
      @player = Player.create!(:first_name => "exist", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => @player.card_id, :member_id => @player.member_id, :blacklist => true, :pin_status => 'created' })
      login_as_admin
      visit players_search_path + "?operation=profile"
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_profile_page
      p = Player.find(@player.id)
      expect(p.member_id).to eq @player.member_id
      expect(p.card_id).to eq @player.card_id
      expect(p.status).to eq 'locked'
      expect(p.has_lock_type?('blacklist')).to eq true
    end

    it '[53.4] Show PIS player info when search  Player Profile PIN changed' do
      @player = Player.create!(:first_name => "exist", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")
      Token.generate(@player.id)
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => @player.card_id, :member_id => @player.member_id, :blacklist => @player.has_lock_type?('blacklist'), :pin_status => 'reset' })
      login_as_admin
      visit players_search_path + "?operation=profile"
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_profile_page
      check_player_info
      p = Player.find(@player.id)
      expect(p.member_id).to eq @player.member_id
      expect(p.card_id).to eq @player.card_id
      expect(p.status).to eq @player.status
      expect(@player.valid_tokens).to eq []
    end

    it '[53.5] Show PIS player info when search  Player Profile, player not exist in Cage' do
      @player = Player.new(:first_name => "exist", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => @player.card_id, :member_id => @player.member_id, :blacklist => @player.has_lock_type?('blacklist'), :pin_status => 'blank' })
      login_as_admin
      visit players_search_path + "?operation=profile"
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_profile_page('no_balance')
      expect(find("label#player_member_id").text).to eq @player.member_id.to_s
      expect(find("label#player_card_id").text).to eq @player.card_id.to_s
      expect(find("label#player_status").text).to eq I18n.t("player_status.not_activate")
      expect(page.source).to have_selector("a#create_pin")
    end
    
    it '[53.6] Card ID not found in PIS' do
      @player = Player.create!(:first_name => "exist", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_raise(Remote::PlayerNotFound)
      login_as_admin
      visit players_search_path + "?operation=profile"
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_profile_page
      p = Player.find(@player.id)
      expect(p.member_id).to eq @player.member_id
      expect(p.card_id).to eq @player.card_id
      expect(p.status).to eq @player.status
    end

    it '[53.7] Show PIS player info when search balance enquiry with Card ID changed' do
      @player = Player.create!(:first_name => "exist", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => '1234567891', :member_id => @player.member_id, :blacklist => @player.has_lock_type?('blacklist'), :pin_status => 'created' })
      login_as_admin
      visit players_search_path + "?operation=balance"
      fill_search_info("member_id", @player.member_id)
      find("#button_find").click
      check_balance_page
      p = Player.find(@player.id)
      expect(p.member_id).to eq @player.member_id
      expect(p.card_id).to eq '1234567891'
      expect(p.status).to eq @player.status
    end
  end

  describe '[54] Reset/Create PIN (PIS)' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info

      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0.0)
    end

    after(:each) do
      clean_dbs
    end

    it '[54.1] Create PIN success in player profile', js: true do
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => "1234567890", :member_id => "123456", :blacklist => false, :pin_status => 'blank' })
      allow_any_instance_of(Requester::Patron).to receive(:reset_pin).and_return({:card_id => "1234567890", :member_id => "123456", :blacklist => false, :pin_status => 'created'})
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.profile")
      wait_for_ajax

      check_search_page("profile")

      fill_search_info_js("card_id", "1234567890")
      find("#button_find").click
      wait_for_ajax

      check_title("tree_panel.profile")
      expect(find("label#player_balance").text).to eq '--'
      expect(find("label#player_member_id").text).to eq '123456'
      expect(find("label#player_card_id").text).to eq '1234567890'
      expect(find("label#player_status").text).to eq I18n.t("player_status.not_activate")

      find("#create_pin").click
      
      wait_for_ajax
      check_title("tree_panel.create_pin")
      fill_in "new_pin", :with => '1111'
      fill_in "confirm_pin", :with => '1111'
      content_list = [I18n.t("confirm_box.set_pin", member_id: '123456')]
      click_pop_up_confirm("confirm_set_pin", content_list)
      
      wait_for_ajax
      check_flash_message I18n.t("reset_pin.set_pin_success", name: "123456")
    end

    it '[54.2] Create PIN fail with PIN is too short in player profile', js: true do
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => "1234567890", :member_id => "123456", :blacklist => false, :pin_status => 'blank' })
      allow_any_instance_of(Requester::Patron).to receive(:reset_pin).and_return({:card_id => "1234567890", :member_id => "123456", :blacklist => false, :pin_status => 'created'})
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.profile")
      wait_for_ajax

      check_search_page("profile")

      fill_search_info_js("card_id", "1234567890")
      find("#button_find").click
      wait_for_ajax

      check_title("tree_panel.profile")
      expect(find("label#player_balance").text).to eq '--'
      expect(find("label#player_member_id").text).to eq '123456'
      expect(find("label#player_card_id").text).to eq '1234567890'
      expect(find("label#player_status").text).to eq I18n.t("player_status.not_activate")

      find("#create_pin").click
      
      wait_for_ajax
      check_title("tree_panel.create_pin")
      fill_in "new_pin", :with => '11'
      fill_in "confirm_pin", :with => '11'
      find("#confirm_set_pin").click
      expect(page).to have_selector('#length_error', visible: true)
      expect(page).to have_selector('#not_match_error', visible: false)
      # expect(find("#length_error").style('')).to eq I18n.t("reset_pin.length_error")
    end

    it '[54.3] Create PIN fail with 2 different PIN in player profile', js: true do
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => "1234567890", :member_id => "123456", :blacklist => false, :pin_status => 'blank' })
      allow_any_instance_of(Requester::Patron).to receive(:reset_pin).and_return({:card_id => "1234567890", :member_id => "123456", :blacklist => false, :pin_status => 'created'})
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.profile")
      wait_for_ajax

      check_search_page("profile")

      fill_search_info_js("card_id", "1234567890")
      find("#button_find").click
      wait_for_ajax

      check_title("tree_panel.profile")
      expect(find("label#player_balance").text).to eq '--'
      expect(find("label#player_member_id").text).to eq '123456'
      expect(find("label#player_card_id").text).to eq '1234567890'
      expect(find("label#player_status").text).to eq I18n.t("player_status.not_activate")

      find("#create_pin").click
      
      wait_for_ajax
      check_title("tree_panel.create_pin")
      fill_in "new_pin", :with => '1111'
      fill_in "confirm_pin", :with => '2222'
      find("#confirm_set_pin").click
      expect(page).to have_selector('#length_error', visible: false)
      expect(page).to have_selector('#not_match_error', visible: true)
    end

    it '[54.4] Reset PIN success in player profile', js: true do
      @player = Player.create!(:first_name => "exist", :last_name => "player", :member_id => '123456', :card_id => '1234567890', :currency_id => 1, :status => "active")
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => "1234567890", :member_id => "123456", :blacklist => false, :pin_status => 'created' })
      allow_any_instance_of(Requester::Patron).to receive(:reset_pin).and_return({:card_id => "1234567890", :member_id => "123456", :blacklist => false, :pin_status => 'reset'})
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0.0)
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.profile")
      wait_for_ajax

      check_search_page("profile")

      fill_search_info_js("member_id", "123456")
      find("#button_find").click
      wait_for_ajax

      check_title("tree_panel.profile")
      expect(find("label#player_balance").text).to eq '0.00'
      expect(find("label#player_member_id").text).to eq '123456'
      expect(find("label#player_card_id").text).to eq '1234567890'
      expect(find("label#player_status").text).to eq I18n.t("player_status.active")

      find("#reset_pin").click
      
      wait_for_ajax
      check_title("tree_panel.reset_pin")
      fill_in "new_pin", :with => '1111'
      fill_in "confirm_pin", :with => '1111'
      content_list = [I18n.t("confirm_box.set_pin", member_id: '123456')]
      click_pop_up_confirm("confirm_set_pin", content_list)
      
      wait_for_ajax
      check_flash_message I18n.t("reset_pin.set_pin_success", name: "123456")
    end

    it '[54.5] Create PIN success in balance enquiry', js: true do
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => "1234567890", :member_id => "123456", :blacklist => false, :pin_status => 'blank' })
      allow_any_instance_of(Requester::Patron).to receive(:reset_pin).and_return({:card_id => "1234567890", :member_id => "123456", :blacklist => false, :pin_status => 'created'})
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.balance")
      wait_for_ajax

      check_search_page

      fill_search_info_js("member_id", "123456")
      find("#button_find").click
      wait_for_ajax

      check_title("tree_panel.balance")
      expect(find("label#player_balance").text).to eq '--'
      expect(find("label#player_member_id").text).to eq '123456'
      expect(find("label#player_card_id").text).to eq '1234567890'
      expect(find("label#player_status").text).to eq I18n.t("player_status.not_activate")

      find("#create_pin").click

      wait_for_ajax
      check_title("tree_panel.create_pin")
      fill_in "new_pin", :with => '1111'
      fill_in "confirm_pin", :with => '1111'
      content_list = [I18n.t("confirm_box.set_pin", member_id: '123456')]
      click_pop_up_confirm("confirm_set_pin", content_list)
      
      wait_for_ajax
      check_flash_message I18n.t("reset_pin.set_pin_success", name: "123456")
    end

    it '[54.6] Create PIN fail in balance enquiry', js: true do
      allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK', :card_id => "1234567890", :member_id => "123456", :blacklist => false, :pin_status => 'blank' })
      allow_any_instance_of(Requester::Patron).to receive(:reset_pin).and_return('connection fail')
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.balance")
      wait_for_ajax

      check_search_page

      fill_search_info_js("member_id", "123456")
      find("#button_find").click
      wait_for_ajax

      check_title("tree_panel.balance")
      expect(find("label#player_balance").text).to eq '--'
      expect(find("label#player_member_id").text).to eq '123456'
      expect(find("label#player_card_id").text).to eq '1234567890'
      expect(find("label#player_status").text).to eq I18n.t("player_status.not_activate")

      find("#create_pin").click

      wait_for_ajax
      check_title("tree_panel.create_pin")
      fill_in "new_pin", :with => '1111'
      fill_in "confirm_pin", :with => '1111'
      content_list = [I18n.t("confirm_box.set_pin", member_id: '123456')]
      click_pop_up_confirm("confirm_set_pin", content_list)
      
      wait_for_ajax
      check_flash_message I18n.t("reset_pin.call_patron_fail")
    end
  end
end
