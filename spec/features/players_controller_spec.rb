require "feature_spec_helper"

describe PlayersController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
    PlayerTransaction.delete_all
    @root_user = User.create!(:uid => 1, :employee_id => 'portal.admin')
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

      allow_any_instance_of(Requester::Standard).to receive(:create_player).and_return('OK')
      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(0.0)
    end

    after(:each) do
      AuditLog.delete_all
      Player.delete_all
    end

    it '[3.1] Show Create Player Page' do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.create_player")
      check_title("tree_panel.create_player")
      expect(page.source).to have_selector("form#new_player input#player_member_id")
      expect(page.source).to have_selector("form#new_player input#player_card_id")
      expect(page.source).to have_selector("form#new_player input#player_player_name")
    end

    it '[3.2] Successfully create player' do
      login_as_admin
      visit new_player_path
      @player = Player.new
      @player.card_id = 1234567890
      @player.member_id = 123456
      @player.player_name = "test player"
      fill_in "player_card_id", :with => @player.card_id
      fill_in "player_member_id", :with => @player.member_id
      fill_in "player_player_name", :with => @player.player_name
      click_button I18n.t("button.create")

      check_title("tree_panel.balance")
      check_flash_message I18n.t("create_player.success", player_name: @player.player_name)

      test_player = Player.find_by_member_id(@player.member_id)
      expect(test_player).not_to be_nil
      test_player.card_id = @player.card_id
      test_player.member_id = @player.member_id
      test_player.player_name = @player.player_name
    end

    it '[3.3] player already exist (member ID)' do
      Player.create!(:player_name => "exist", :member_id => 123456, :currency_id => 1, :balance => 0, :status => "active")
      login_as_admin
      visit new_player_path
      @player = Player.new
      @player.card_id = 1234567890
      @player.member_id = 123456
      @player.player_name = "test player"
      fill_in "player_card_id", :with => @player.card_id
      fill_in "player_member_id", :with => @player.member_id
      fill_in "player_player_name", :with => @player.player_name
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
      @player.player_name = "test player"
      fill_in "player_card_id", :with => @player.card_id
      fill_in "player_player_name", :with => @player.player_name
      click_button I18n.t("button.create")

      check_title("tree_panel.create_player")
      check_flash_message I18n.t("create_player.member_id_length_error")
    end

    it '[3.5] empty Player name' do
      login_as_admin
      visit new_player_path
      @player = Player.new
      @player.card_id = 1234567890
      @player.member_id = 123456
      @player.player_name = "test player"
      fill_in "player_card_id", :with => @player.card_id
      fill_in "player_member_id", :with => @player.member_id
      click_button I18n.t("button.create")

      check_title("tree_panel.create_player")
      check_flash_message I18n.t("create_player.name_blank_error")
    end

    it '[3.6] Audit log for successful create player' do
      login_as_admin
      visit new_player_path
      @player = Player.new
      @player.card_id = 1234567890
      @player.member_id = 123456
      @player.player_name = "test player"
      fill_in "player_card_id", :with => @player.card_id
      fill_in "player_member_id", :with => @player.member_id
      fill_in "player_player_name", :with => @player.player_name
      click_button I18n.t("button.create")

      audit_log = AuditLog.find_by_audit_target("player")
      audit_log.should_not be_nil
      audit_log.audit_target.should == "player"
      audit_log.action_by.should == @root_user.employee_id
      audit_log.action_type.should == "create"
      audit_log.action.should == "create"
      audit_log.action_status.should == "success"
      audit_log.action_error.should be_nil
      audit_log.ip.should_not be_nil
      audit_log.session_id.should_not be_nil
      audit_log.description.should_not be_nil
    end

    it '[3.7] Audit log for fail create player' do
      Player.create!(:player_name => "exist", :member_id => 123456, :currency_id => 1, :balance => 0, :status => "active")
      login_as_admin
      visit new_player_path
      @player = Player.new
      @player.card_id = 1234567890
      @player.member_id = 123456
      @player.player_name = "test player"
      fill_in "player_card_id", :with => @player.card_id
      fill_in "player_member_id", :with => @player.member_id
      fill_in "player_player_name", :with => @player.player_name
      click_button I18n.t("button.create")

      audit_log = AuditLog.find_by_audit_target("player")
      audit_log.should_not be_nil
      audit_log.audit_target.should == "player"
      audit_log.action_by.should == @root_user.employee_id
      audit_log.action_type.should == "create"
      audit_log.action.should == "create"
      audit_log.action_status.should == "fail"
      audit_log.action_error.should_not be_nil
      audit_log.ip.should_not be_nil
      audit_log.session_id.should_not be_nil
      audit_log.description.should_not be_nil
    end

    it '[3.8] click unauthorized action', js: true do 
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["create"])
      visit home_path
      set_permission(@test_user,"cashier",:player,[])
      click_link I18n.t("tree_panel.create_player")
      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end     
    
    it '[3.9] click link to the unauthorized page', js: true do 
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,[])
      visit new_player_path
      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end     
    
    it '[3.10] unauthorization for create player', js: true do 
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
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
      @player.player_name = "test player"
      fill_in "player_member_id", :with => @player.member_id
      fill_in "player_player_name", :with => @player.player_name
      click_button I18n.t("button.create")

      check_title("tree_panel.create_player")
      check_flash_message I18n.t("create_player.card_id_length_error")
    end

    it '[3.12] member id and card ID can only input number' do
      login_as_admin
      visit new_player_path
      fill_in "player_card_id", :with => '..//.-=-++-'
      fill_in "player_member_id", :with => '123456'
      fill_in "player_player_name", :with => '$$$$@@@'
      click_button I18n.t("button.create")

      check_title("tree_panel.create_player")
      check_flash_message I18n.t("create_player.card_id_only_number_allowed_error")
      
      fill_in "player_card_id", :with => '1234567890'
      fill_in "player_member_id", :with => 'hahaha'
      fill_in "player_player_name", :with => '$$$$@@@'
      click_button I18n.t("button.create")

      check_title("tree_panel.create_player")
      check_flash_message I18n.t("create_player.member_id_only_number_allowed_error")
    end

    it '[3.13] player already exist (card ID)' do
      Player.create!(:player_name => "exist", :card_id => 1234567890, :currency_id => 1, :balance => 0, :status => "active")
      login_as_admin
      visit new_player_path
      @player = Player.new
      @player.card_id = 1234567890
      @player.member_id = 123456
      @player.player_name = "test player"
      fill_in "player_card_id", :with => @player.card_id
      fill_in "player_member_id", :with => @player.member_id
      fill_in "player_player_name", :with => @player.player_name
      click_button I18n.t("button.create")

      check_title("tree_panel.create_player")
      check_flash_message I18n.t("create_player.card_id_exist", card_id: @player.card_id)
    end
  end
  
  describe '[4] Search player by membership ID' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info

      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(0.0)
    end

    after(:each) do
      Player.delete_all
    end

    it '[4.1] Show search Page' do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.balance")
      check_search_page
    end

    it '[4.2] successfully search player' do
      @player = Player.create!(:player_name => "exist", :member_id => 123456, :card_id => 1234567890, :currency_id => 1, :balance => 0, :status => "active")
      login_as_admin
      visit players_search_path + "?operation=balance"
      fill_search_info("member_id", @player.member_id)
      find("#button_find").click
      check_balance_page
      check_player_info
    end
    
    it '[4.3] fail to search player' do
      @player = Player.new
      @player.member_id = 123456
      @player.player_name = "test player"
      login_as_admin
      visit players_search_path + "?operation=balance"
      fill_search_info("member_id", @player.member_id)
      find("#button_find").click
      check_not_found
      click_link I18n.t("button.create")
    end
    
    it '[4.4] direct to create player' do
      @player = Player.new
      @player.member_id = 123456
      @player.player_name = "test player"
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

      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(0.0)
    end

    after(:each) do
      Player.delete_all
    end

    it '[5.1] view player balance enquiry' do
      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(99.99)

      @player = Player.create!(:player_name => "exist", :member_id => 123456, :card_id => 1234567890, :currency_id => 1, :balance => 9999, :status => "active")
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.balance")
      check_search_page
      fill_search_info("member_id", @player.member_id)
      find("#button_find").click
      
      check_player_info
      check_balance_page

      expect(page.source).to have_selector("div a#balance_deposit")
      expect(page.source).to have_selector("div a#balance_withdraw")
      expect(page.source).to have_selector("div a#close_to_home")
    end

    it '[5.2] click unauthorized action', :js => true do 
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
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
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,[])
      visit balance_path
      wait_for_ajax
      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
    end     
    
    it '[5.4] authorized to search and unauthorized to create' do 
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["balance"])
      visit players_search_path + "?operation=balance"
      fill_search_info("member_id", 123456)

      find("#button_find").click
      check_not_found
      expect(page.source).to_not have_content(I18n.t("search_error.create_player"))
    end     
    
    it '[5.5] Return to Cage home' do
      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(99.99)

      @player = Player.create!(:player_name => "exist", :member_id => 123456, :card_id => 1234567890, :currency_id => 1, :balance => 9999, :status => "active")
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.balance")
      check_search_page
      fill_search_info("member_id", @player.member_id)
      find("#button_find").click
      
      check_balance_page
      check_player_info
      
      expect(page.source).to have_selector("div a#balance_deposit")
      expect(page.source).to have_selector("div a#balance_withdraw")
      expect(page.source).to have_selector("div a#close_to_home")

      find("div a#close_to_home").click
      expect(page).to have_content @location
      expect(page).to have_content "Waiting for accounting date"
      expect(page).to have_content "Waiting for shift"
    end

    it '[5.6] unauthorized to all actions' do
      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(99.99)

      @player = Player.create!(:player_name => "exist", :member_id => 123456, :card_id => 1234567890, :currency_id => 1, :balance => 9999, :status => "active")
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["balance"])
      set_permission(@test_user,"cashier",:player_transaction,[])
      visit home_path
      click_link I18n.t("tree_panel.balance")
      check_search_page
      fill_search_info("member_id", @player.member_id)
      find("#button_find").click

      check_balance_page
      check_player_info
      
      expect(page.source).to_not have_selector("div a#balance_deposit")
      expect(page.source).to_not have_selector("div a#balance_withdraw")
      expect(page.source).to have_selector("div a#close_to_home")
    end
    
    it '[5.7] unathorized to balance enquriy ' do 
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,[])
      visit home_path
      first("aside#left-panel ul li#nav_balance_enquiry").should be_nil
    end     
  end
  
  describe '[12] Search player by card ID' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info

      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(0.0)
    end

    after(:each) do
      Player.delete_all
    end

    it '[12.1] Show search Page' do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.balance")
      check_search_page
    end

    it '[12.2] successfully search player' do
      @player = Player.create!(:player_name => "exist", :member_id => 123456, :card_id => 1234567890, :currency_id => 1, :balance => 0, :status => "active")
      login_as_admin
      visit players_search_path + "?operation=balance"
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_balance_page
      check_player_info
    end
    
    it '[12.3] fail to search player' do
      @player = Player.new
      @player.member_id = 123456
      @player.card_id = 1234567890
      @player.player_name = "test player"
      login_as_admin
      visit players_search_path + "?operation=balance"
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_not_found
      click_link I18n.t("button.create")
    end
    
    it '[12.4] direct to create player' do
      @player = Player.new
      @player.member_id = 123456
      @player.card_id = 1234567890
      @player.player_name = "test player"
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
  
  describe '[14] Edit Player' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      
      @player = Player.create!(:player_name => "test", :member_id => 123456, :card_id => 1234567890, :currency_id => 1, :balance => 0, :status => "active")
      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(0.0)
    end

    after(:each) do
      Player.delete_all
    end

    it '[14.1] successfully edit player' do
      updated_card_id = 12345678900987654321
      updated_player_name = "updated"
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.profile")
      check_search_page("profile")
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_profile_page
      check_player_info

      click_link I18n.t("button.edit")
      check_edit_page
      fill_in "player_card_id", :with => updated_card_id
      fill_in "player_player_name", :with => updated_player_name
      click_button I18n.t("button.confirm")

      @player.reload
      expect(@player.card_id).to eq updated_card_id.to_s
      expect(@player.player_name).to eq updated_player_name
      check_profile_page
      check_player_info
    end
    
    it '[14.2] player name cannot be empty', :js => true do
      updated_card_id = 12345678900987654321
      updated_player_name = ""
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.profile")
      fill_search_info_js("card_id", @player.card_id)
      find("#button_find").click
      check_profile_page
      check_player_info

      click_link I18n.t("button.edit")
      wait_for_ajax
      check_edit_page
      fill_in "player_card_id", :with => updated_card_id
      fill_in "player_player_name", :with => updated_player_name
      click_button I18n.t("button.confirm")
      
      labels = all("label.invisible_error")
      expect(labels[0][:style]).to_not include("visible")
      expect(labels[1][:style]).to include("visible")
    end
    
    it '[14.3] card ID cannot be empty', :js => true do
      updated_card_id = ""
      updated_player_name = "updated"
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.profile")
      fill_search_info_js("card_id", @player.card_id)
      find("#button_find").click
      check_profile_page
      check_player_info

      click_link I18n.t("button.edit")
      wait_for_ajax
      check_edit_page
      fill_in "player_card_id", :with => updated_card_id
      fill_in "player_player_name", :with => updated_player_name
      click_button I18n.t("button.confirm")
      
      labels = all("label.invisible_error")
      expect(labels[0][:style]).to include("visible")
      expect(labels[1][:style]).to_not include("visible")
    end
    
    it '[14.4] duplicated card ID'do
      @player2 = Player.create!(:player_name => "test", :member_id => 123457, :card_id => 12345678901234567890, :currency_id => 1, :balance => 0, :status => "active")
      updated_card_id = 12345678901234567890
      updated_player_name = "updated"
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.profile")
      check_search_page("profile")
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_profile_page
      check_player_info

      click_link I18n.t("button.edit")
      check_edit_page
      fill_in "player_card_id", :with => updated_card_id
      fill_in "player_player_name", :with => updated_player_name
      click_button I18n.t("button.confirm")

      check_edit_page
      check_flash_message I18n.t("update_player.duplicate")
    end

    it '[14.5] audit log for edit player'do
      updated_card_id = 12345678900987654321
      updated_player_name = "updated"
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.profile")
      check_search_page("profile")
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_profile_page
      check_player_info

      click_link I18n.t("button.edit")
      check_edit_page
      fill_in "player_card_id", :with => updated_card_id
      fill_in "player_player_name", :with => updated_player_name
      click_button I18n.t("button.confirm")

      player = Player.find(@player.id)
      expect(player.card_id).to eq updated_card_id.to_s
      expect(player.player_name).to eq updated_player_name
      
      audit_log = AuditLog.find_by_audit_target("player")
      audit_log.should_not be_nil
      audit_log.audit_target.should == "player"
      audit_log.action_by.should == @root_user.employee_id
      audit_log.action_type.should == "update"
      audit_log.action.should == "edit"
      audit_log.action_status.should == "success"
      audit_log.action_error.should be_nil
      audit_log.ip.should_not be_nil
      audit_log.session_id.should_not be_nil
      audit_log.description.should_not be_nil
    end
    
    it '[14.6] audit log for fail to edit player'do
      @player2 = Player.create!(:player_name => "test", :member_id => 123457, :card_id => 12345678901234567890, :currency_id => 1, :balance => 0, :status => "active")
      updated_card_id = 12345678901234567890
      updated_player_name = "updated"
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.profile")
      check_search_page("profile")
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_profile_page
      check_player_info

      click_link I18n.t("button.edit")
      check_edit_page
      fill_in "player_card_id", :with => updated_card_id
      fill_in "player_player_name", :with => updated_player_name
      click_button I18n.t("button.confirm")

      check_edit_page
      check_flash_message I18n.t("update_player.duplicate")
      
      audit_log = AuditLog.find_by_audit_target("player")
      audit_log.should_not be_nil
      audit_log.audit_target.should == "player"
      audit_log.action_by.should == @root_user.employee_id
      audit_log.action_type.should == "update"
      audit_log.action.should == "edit"
      audit_log.action_status.should == "fail"
      audit_log.action_error.should_not be_nil
      audit_log.ip.should_not be_nil
      audit_log.session_id.should_not be_nil
      audit_log.description.should_not be_nil
    end

    it '[14.7] unauthorized for edit player' do
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,["profile"])
      visit home_path
      click_link I18n.t("tree_panel.profile")
      check_search_page("profile")
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_profile_page
      check_player_info

      expect(page.source).to_not have_selector("a#edit_player")
    end
      
    it '[14.8] close profile'do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.profile")
      check_search_page("profile")
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_profile_page
      check_player_info

      find("div a#close_to_home").click
      check_home_page
    end
      
    it '[14.9] cancel edit' do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.profile")
      check_search_page("profile")
      fill_search_info("card_id", @player.card_id)
      find("#button_find").click
      check_profile_page
      check_player_info

      click_link I18n.t("button.edit")
      check_edit_page
      click_link I18n.t("button.cancel")
      check_profile_page
    end
    
    it '[14.10] unauthorized for view profile ' do 
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,[])
      visit home_path
      first("aside#left-panel ul li#nav_player_profile").should be_nil
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
      expect(page).to have_selector "div#confirm_#{@lock_or_unlock}_player_dialog"
      expect(find("div#confirm_#{@lock_or_unlock}_player_dialog")[:style]).to include "none"
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
      expect(find("div#confirm_#{@lock_or_unlock}_player_dialog")[:style]).to_not include "none"

      expected_flash_message = I18n.t("#{@lock_or_unlock}_player.success", player_name: @player.player_name)

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

      @player = Player.create!(:player_name => "test", :member_id => 123456, :card_id => 1234567890, :currency_id => 1, :balance => 0, :status => "active")

      allow_any_instance_of(Requester::Standard).to receive(:get_player_balance).and_return(0.0)
      allow_any_instance_of(Requester::Standard).to receive(:lock_player).and_return('OK')
      allow_any_instance_of(Requester::Standard).to receive(:unlock_player).and_return('OK')
    end

    after(:each) do
      AuditLog.delete_all
      Player.delete_all
    end

    it '[15.1] Successfully Lock player', js: true do
      lock_or_unlock_player_and_check
    end 

    it '[15.2] Successfully unlock player', js: true do
      @player.status = "locked"
      @player.save

      lock_or_unlock_player_and_check
    end 

    it '[15.3] unauthorized to lock/unlock' do 
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
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
      expect(audit_log.action_by).to eq @root_user.employee_id
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

      lock_or_unlock_player_and_check

      audit_log = AuditLog.find_by_audit_target("player")
      expect(audit_log).to_not be_nil
      expect(audit_log.audit_target).to eq "player"
      expect(audit_log.action_by).to eq @root_user.employee_id
      expect(audit_log.action_type).to eq "update"
      expect(audit_log.action).to eq "unlock"
      expect(audit_log.action_status).to eq "success"
      expect(audit_log.action_error).to be_nil
      expect(audit_log.ip).to_not be_nil
      expect(audit_log.session_id).to_not be_nil
      expect(audit_log.description).to_not be_nil
    end

  end
end
