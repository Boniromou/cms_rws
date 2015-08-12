require "feature_spec_helper"

describe StationsController do
	before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
    @root_user = User.create!(:uid => 1, :employee_id => 'portal.admin')
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[22] List Active/Inactive Station' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      @location1 = Location.create!(:name => "LOCATION1", :status => "active")
      @location2 = Location.create!(:name => "LOCATION2", :status => "active")
      @station1 = Station.create!(:name => "STATION1", :status => "active", :location_id => @location1.id, :terminal_id => "111122223333JJJJ")
      @station2 = Station.create!(:name => "STATION2", :status => "inactive", :location_id => @location1.id)
      @station3 = Station.create!(:name => "STATION3", :status => "active", :location_id => @location2.id)
      @station4 = Station.create!(:name => "STATION4", :status => "inactive", :location_id => @location2.id)
    end

    after(:each) do
      Station.delete_all
      Location.delete_all
    end

    it '[22.1] List active station' do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.station")
      check_title("tree_panel.station")
      station_list = [@station1,@station3]
      permission_list = {:change_status => true, :register => true}
      check_stations_table_items(station_list,permission_list)
    end

    it '[22.2] List inactive station' do
      login_as_admin
      visit home_path
      click_link I18n.t("tree_panel.station")
      check_title("tree_panel.station")
      click_link I18n.t("general.inactive")
      station_list = [@station2,@station4]
      permission_list = {:change_status => true, :register => true}
      check_stations_table_items(station_list,permission_list)
    end

		it '[22.3] Unauthorized list active/inactive station', js: true do
			@test_user = User.create!(:uid => 2, :employee_id => 'test.user')
			login_as_not_admin(@test_user)
			set_permission(@test_user,"cashier",:station,[])
			visit home_path
			expect(page.source).to_not have_selector("li#nav_station")
		end

		it '[22.4] Click link to the list station page', js: true do
			@test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:station,[])
      visit list_stations_path("active")
      wait_for_ajax
      check_home_page
      check_flash_message I18n.t("flash_message.not_authorize")
		end
  end

  describe '[23] Add station' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
    end

    after(:each) do
      AuditLog.delete_all
      Station.delete_all
      Location.delete_all
    end

    it '[23.1] Add station success', :js => true do
      @location1 = Location.create!(:name => "LOCATION1", :status => "active")
      login_as_admin
      visit list_stations_path("active")
      @station1 = Station.new
      @station1.name = "STATION1"
      fill_in "name", :with => @station1.name
      
      content_list = [I18n.t("confirm_box.add_station"),@station1.name]
      click_pop_up_confirm("add_station_confirm", content_list)

      check_title("tree_panel.station")
      check_flash_message I18n.t("station.add_success", {location: @location1.name, name: @station1.name})
      
      @station1 = Station.find_by_name(@station1.name)
      station_list = [@station1]
      permission_list = {:change_status => true, :register => true}
      check_stations_table_items(station_list,permission_list)
    end

    it '[23.2] Duplicate station name', :js => true do
      @location1 = Location.create!(:name => "LOCATION1", :status => "active")
      @station1 = Station.create!(:name => "STATION1", :status => "active", :location_id => @location1.id)
      login_as_admin
      visit list_stations_path("active")
      fill_in "name", :with => @station1.name
      
      content_list = [I18n.t("confirm_box.add_station"),@station1.name]
      click_pop_up_confirm("add_station_confirm",content_list)

      check_title("tree_panel.station")
      check_flash_message I18n.t("station.already_existed", {name: @station1.name})
    end

    it '[23.3] Add station with no active location', :js => true do
      login_as_admin
      visit list_stations_path("active")
      fill_in "name", :with => "station1"
      confirm_btn = find("button#add_station_confirm")
      expect(confirm_btn[:class]).to have_content "disabled"	    	
    end

    it '[23.4] Add station with no station name', :js => true do
      @location1 = Location.create!(:name => "LOCATION1", :status => "active")
      login_as_admin
      visit list_stations_path("active")
      confirm_btn = find("button#add_station_confirm")
      expect(confirm_btn[:class]).to have_content "disabled"	    	
    end

    it '[23.5] add station with disable location', :js => true do
      @location1 = Location.create!(:name => "LOCATION1", :status => "active")
      login_as_admin
      visit list_stations_path("active")
      fill_in "name", :with => "station1"
      
      @location1.status = "inactive"
      @location1.save

      content_list = [I18n.t("confirm_box.add_station"),"station1"]
      click_pop_up_confirm("add_station_confirm",content_list)

      check_title("tree_panel.station")
      check_flash_message I18n.t("station.location_invalid")
    end

    it '[23.6] Unauthorized add station' do
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      set_permission(@test_user,"cashier",:station, ["list"])
      login_as_not_admin(@test_user)
      visit home_path
      click_link I18n.t("tree_panel.station")
      check_title("tree_panel.station")
      expect(page.source).to have_selector("table#datatable_col_reorder")
      expect(page.source).to_not have_selector("form#addstation")
    end

    it '[23.7] Audit log for add sation', :js => true do
      @location1 = Location.create!(:name => "LOCATION1", :status => "active")
      login_as_admin
      visit list_stations_path("active")
      @station1 = Station.new
      @station1.name = "STATION1"
      fill_in "name", :with => @station1.name
      
      content_list = [I18n.t("confirm_box.add_station"),@station1.name]
      click_pop_up_confirm("add_station_confirm", content_list)

      check_title("tree_panel.station")
      check_flash_message I18n.t("station.add_success", {location: @location1.name, name: @station1.name})

      audit_log = AuditLog.find_by_audit_target("station")
      audit_log.should_not be_nil
      audit_log.audit_target.should == "station"
      audit_log.action_by.should == @root_user.employee_id
      audit_log.action_type.should == "create"
      audit_log.action.should == "create"
      audit_log.action_status.should == "success"
      audit_log.action_error.should be_nil
      audit_log.ip.should_not be_nil
      audit_log.session_id.should_not be_nil
      audit_log.description.should_not be_nil
    end

    it '[23.8] Audit log for fail to add sation', :js => true do
      @location1 = Location.create!(:name => "LOCATION1", :status => "active")
      @station1 = Station.create!(:name => "STATION1", :status => "active", :location_id => @location1.id)
      login_as_admin
      visit list_stations_path("active")
      fill_in "name", :with => @station1.name
      
      content_list = [I18n.t("confirm_box.add_station"),@station1.name]
      click_pop_up_confirm("add_station_confirm",content_list)

      check_title("tree_panel.station")
      check_flash_message I18n.t("station.already_existed", {name: @station1.name})

      audit_log = AuditLog.find_by_audit_target("station")
      audit_log.should_not be_nil
      audit_log.audit_target.should == "station"
      audit_log.action_by.should == @root_user.employee_id
      audit_log.action_type.should == "create"
      audit_log.action.should == "create"
      audit_log.action_status.should == "fail"
      audit_log.action_error.should_not be_nil
      audit_log.ip.should_not be_nil
      audit_log.session_id.should_not be_nil
      audit_log.description.should_not be_nil
    end
	end

	describe '[24] Enable/Disable Station' do
		before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      @location1 = Location.create!(:name => "LOCATION1", :status => "active")
      @location2 = Location.create!(:name => "LOCATION2", :status => "active")
      @station1 = Station.create!(:name => "STATION1", :status => "active", :location_id => @location1.id, :terminal_id => "111122223333JJJJ")
      @station2 = Station.create!(:name => "STATION2", :status => "inactive", :location_id => @location1.id)
      @station3 = Station.create!(:name => "STATION3", :status => "active", :location_id => @location2.id)
      @station4 = Station.create!(:name => "STATION4", :status => "inactive", :location_id => @location2.id)
    end

    after(:each) do
      AuditLog.delete_all
      Station.delete_all
      Location.delete_all
    end

    it '[24.1] Enable stcation success', :js => true do
      login_as_admin
      visit list_stations_path("active")
      click_link I18n.t("general.inactive")
      
      content_list = [I18n.t("confirm_box.enable_station", name: @station2.full_name)]
      click_pop_up_confirm("change_station_status_" + @station2.id.to_s, content_list)
      
      check_flash_message I18n.t("station.enable_success", name: @station2.full_name)
    end

    it '[24.2] Disable stcation success', :js => true do
      login_as_admin
      visit list_stations_path("active")
      
      content_list = [I18n.t("confirm_box.disable_station", name: @station1.full_name)]
      click_pop_up_confirm("change_station_status_" + @station1.id.to_s, content_list)
      
      check_flash_message I18n.t("station.disable_success", name: @station1.full_name)
    end

    it '[24.3] Enable station fail case', :js => true do
      login_as_admin
      visit list_stations_path("active")
      click_link I18n.t("general.inactive")
      sleep(5 )
      @station2.status = "active"
      @station2.save
      
      
      content_list = [I18n.t("confirm_box.enable_station", name: @station2.full_name)]
      click_pop_up_confirm("change_station_status_" + @station2.id.to_s, content_list)
      
      check_flash_message I18n.t("station.already_enabled", name: @station2.full_name)
		end

		it '[24.4] Unauthorized enable/disable station' do
			@test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:station,["list","register"])

      visit home_path
      click_link I18n.t("tree_panel.station")
      check_title("tree_panel.station")
      station_list = [@station1,@station3]
      permission_list = {:change_status => false, :register => true}
      check_stations_table_items(station_list,permission_list)
		end

		it '[24.5] Audit log for enable/disable sttion (success case)', :js => true do
      login_as_admin
      visit list_stations_path("active")
      click_link I18n.t("general.inactive")
      
      content_list = [I18n.t("confirm_box.enable_station", name: @station2.full_name)]
      click_pop_up_confirm("change_station_status_" + @station2.id.to_s, content_list)
      
      check_flash_message I18n.t("station.enable_success", name: @station2.full_name)

      audit_log = AuditLog.find_by_audit_target("station")
      expect(audit_log).to_not be_nil
      expect(audit_log.audit_target).to eq "station"
      expect(audit_log.action_by).to eq @root_user.employee_id
      expect(audit_log.action_type).to eq "update"
      expect(audit_log.action).to eq "enable"
      expect(audit_log.action_status).to eq "success"
      expect(audit_log.action_error).to be_nil
      expect(audit_log.ip).to_not be_nil
      expect(audit_log.session_id).to_not be_nil
      expect(audit_log.description).to_not be_nil
		end

		it '[24.6] Audit log for enable/disable sttion (fail case)', :js => true do
      login_as_admin
      visit list_stations_path("active")
      click_link I18n.t("general.inactive")
      @station2.status = "active"
      @station2.save
      
      content_list = [I18n.t("confirm_box.enable_station", name: @station2.full_name)]
      click_pop_up_confirm("change_station_status_" + @station2.id.to_s, content_list)
      
      check_flash_message I18n.t("station.already_enabled", name: @station2.full_name)

      audit_log = AuditLog.find_by_audit_target("station")
      expect(audit_log).to_not be_nil
      expect(audit_log.audit_target).to eq "station"
      expect(audit_log.action_by).to eq @root_user.employee_id
      expect(audit_log.action_type).to eq "update"
      expect(audit_log.action).to eq "enable"
      expect(audit_log.action_status).to eq "fail"
      expect(audit_log.action_error).to_not be_nil
      expect(audit_log.ip).to_not be_nil
      expect(audit_log.session_id).to_not be_nil
      expect(audit_log.description).to_not be_nil
		end

    it '[24.7] Enable station fail when location is disabled', :js => true do
      @location1.status = "inactive"
      @location1.save
      login_as_admin
      visit list_stations_path("active")
      click_link I18n.t("general.inactive")
      
      content_list = [I18n.t("confirm_box.enable_station", name: @station2.full_name)]
      click_pop_up_confirm("change_station_status_" + @station2.id.to_s, content_list)
      
      check_flash_message I18n.t("station.location_invalid", name: @station2.full_name)
		end
	end
	
  describe '[25] Register/un-register Terminal' do
		before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      @location1 = Location.create!(:name => "LOCATION1", :status => "active")
      @location2 = Location.create!(:name => "LOCATION2", :status => "active")
      @station1 = Station.create!(:name => "STATION1", :status => "active", :location_id => @location1.id)
      @station2 = Station.create!(:name => "STATION2", :status => "inactive", :location_id => @location1.id)
      @station3 = Station.create!(:name => "STATION3", :status => "active", :location_id => @location2.id)
      @station4 = Station.create!(:name => "STATION4", :status => "inactive", :location_id => @location2.id)
    end

    after(:each) do
      AuditLog.delete_all
      Station.delete_all
      Location.delete_all
    end

    it '[25.1] Register terminal (success case)', :js => true do
      login_as_admin
      visit list_stations_path("active")
      terminal_id = "AAAABBBBCCCCDDDD"
      set_terminal_id(terminal_id)
      content_list = [I18n.t("terminal_id.confirm_reg1"), terminal_id, I18n.t("terminal_id.confirm_reg2", name: @station1.full_name)]
      click_pop_up_confirm("register_terminal_" + @station1.id.to_s, content_list)

      check_flash_message I18n.t("terminal_id.register_success", station_name: @station1.full_name)
      @station1.reload
      expect(@station1.terminal_id).to eq terminal_id
    end
    
    it '[25.2] Register terminal (fail case, station already register)', :js => true do
      login_as_admin
      visit list_stations_path("active")
      terminal_id = "AAAABBBBCCCCDDDD"
      set_terminal_id(terminal_id)
      @station1.terminal_id = terminal_id
      @station1.save

      content_list = [I18n.t("terminal_id.confirm_reg1"), terminal_id, I18n.t("terminal_id.confirm_reg2", name: @station1.full_name)]
      click_pop_up_confirm("register_terminal_" + @station1.id.to_s, content_list)

      check_flash_message I18n.t("terminal_id.station_already_reg")
    end
    
    it '[25.3] Register terminal (fail case, terminal_id already register)', :js => true do
      login_as_admin
      visit list_stations_path("active")
      terminal_id = "AAAABBBBCCCCDDDD"
      set_terminal_id(terminal_id)
      @station2.terminal_id = terminal_id
      @station2.save

      content_list = [I18n.t("terminal_id.confirm_reg1"), terminal_id, I18n.t("terminal_id.confirm_reg2", name: @station1.full_name)]
      click_pop_up_confirm("register_terminal_" + @station1.id.to_s, content_list)

      check_flash_message I18n.t("terminal_id.terminal_already_reg", station_name: @station2.full_name)
    end

		it '[25.4] unauthorized Register terminal' do
			@test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:station,["list","change_status"])

      visit home_path
      click_link I18n.t("tree_panel.station")
      check_title("tree_panel.station")
      station_list = [@station1,@station3]
      permission_list = {:change_status => true, :register => false}
      check_stations_table_items(station_list,permission_list)
		end

    it '[25.5] Un-Register terminal (success case)', :js => true do
      terminal_id = "AAAABBBBCCCCDDDD"
      @station1.terminal_id = terminal_id
      @station1.save
      login_as_admin
      visit list_stations_path("active")

      content_list = [I18n.t("terminal_id.confirm_unreg", :name => @station1.full_name, :terminal_id => terminal_id)]
      click_pop_up_confirm("unregister_terminal_" + @station1.id.to_s, content_list)

      check_flash_message I18n.t("terminal_id.unregister_success", station_name: @station1.full_name)
      @station1.reload
      expect(@station1.terminal_id).to be_nil
    end

    it '[25.6] Un-Register terminal ( clase)', :js => true do
      terminal_id = "AAAABBBBCCCCDDDD"
      @station1.terminal_id = terminal_id
      @station1.save
      login_as_admin
      visit list_stations_path("active")

      @station1.terminal_id = nil
      @station1.save

      content_list = [I18n.t("terminal_id.confirm_unreg", :name => @station1.full_name, :terminal_id => terminal_id)]
      click_pop_up_confirm("unregister_terminal_" + @station1.id.to_s, content_list)

      check_flash_message I18n.t("terminal_id.unregister_fail")
      @station1.reload
      expect(@station1.terminal_id).to be_nil
    end
		
    it '[25.7] audit log for register terminal', :js => true do
      login_as_admin
      visit list_stations_path("active")
      terminal_id = "AAAABBBBCCCCDDDD"
      set_terminal_id(terminal_id)
      content_list = [I18n.t("terminal_id.confirm_reg1"), terminal_id, I18n.t("terminal_id.confirm_reg2", name: @station1.full_name)]
      click_pop_up_confirm("register_terminal_" + @station1.id.to_s, content_list)

      check_flash_message I18n.t("terminal_id.register_success", station_name: @station1.full_name)
      @station1.reload
      expect(@station1.terminal_id).to eq terminal_id

      audit_log = AuditLog.find_by_audit_target("station")
      expect(audit_log).to_not be_nil
      expect(audit_log.audit_target).to eq "station"
      expect(audit_log.action_by).to eq @root_user.employee_id
      expect(audit_log.action_type).to eq "update"
      expect(audit_log.action).to eq "register"
      expect(audit_log.action_status).to eq "success"
      expect(audit_log.action_error).to be_nil
      expect(audit_log.ip).to_not be_nil
      expect(audit_log.session_id).to_not be_nil
      expect(audit_log.description).to_not be_nil
		end
		
    it '[25.8] audit log for fail to register terminal', :js => true do
      login_as_admin
      visit list_stations_path("active")
      terminal_id = "AAAABBBBCCCCDDDD"
      set_terminal_id(terminal_id)
      @station1.terminal_id = terminal_id
      @station1.save

      content_list = [I18n.t("terminal_id.confirm_reg1"), terminal_id, I18n.t("terminal_id.confirm_reg2", name: @station1.full_name)]
      click_pop_up_confirm("register_terminal_" + @station1.id.to_s, content_list)

      check_flash_message I18n.t("terminal_id.station_already_reg")

      audit_log = AuditLog.find_by_audit_target("station")
      expect(audit_log).to_not be_nil
      expect(audit_log.audit_target).to eq "station"
      expect(audit_log.action_by).to eq @root_user.employee_id
      expect(audit_log.action_type).to eq "update"
      expect(audit_log.action).to eq "register"
      expect(audit_log.action_status).to eq "fail"
      expect(audit_log.action_error).to_not be_nil
      expect(audit_log.ip).to_not be_nil
      expect(audit_log.session_id).to_not be_nil
      expect(audit_log.description).to_not be_nil
		end
  end


end
