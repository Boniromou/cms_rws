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
      @station1 = Station.create!(:name => "STATION1", :status => "active", :location_id => @location1.id, :machine_id => "111122223333JJJJ")
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
			set_permission(@test_user,"cashier",:location,[])
			visit home_path
			expect(page.source).to_not have_selector("li#nav_station")
		end

		it '[22.4] Click link to the list location page', js: true do
			@test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:player,[])
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

    it '[23.1] Add location success', :js => true do
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
      
      content_list = [I18n.t("confirm_box.add_station"),@station1.name]
      click_pop_up_confirm("add_station_confirm",content_list)

      check_title("tree_panel.station")
      check_flash_message I18n.t("station.location_invalid")
    end

    it '[23.6] Unauthorized add station' do
      @test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      set_permission(@test_user,"cashier",:location, ["list"])
      login_as_admin
      #login_as_not_admin(@test_user)
      click_link I18n.t("tree_panel.location")
      check_title("tree_panel.location")
        expect(page.source).to have_selector("table#datatable_col_reorder")
      expect(page.source).to_not have_selector("input#location_name")
      expect(page.source).to_not have_selector("input#add_location_submit")
      User.delete_all
    end

	    it '[20.5] Audit log for add location' do
	    	login_as_admin
	    	visit list_locations_path("active")
	    	@location = Location.new
	    	@location.name = "test"
	    	fill_in "location_name", :with => @location.name
	    	click_button I18n.t("button.add")

	    	audit_log = AuditLog.find_by_audit_target("location")
      		audit_log.should_not be_nil
      		audit_log.audit_target.should == "location"
      		audit_log.action_by.should == @root_user.employee_id
      		audit_log.action_type.should == "add"
      		audit_log.action.should == "add"
      		audit_log.action_status.should == "success"
      		audit_log.action_error.should be_nil
      		audit_log.ip.should_not be_nil
      		audit_log.session_id.should_not be_nil
      		audit_log.description.should_not be_nil
	    end

	    it '[20.6] Audit log for fail to add location' do
	    	Location.create!(:name => "AAA", :status => "active")
	    	login_as_admin
	    	visit list_locations_path("active")
	    	@location = Location.new
	    	@location.name = "aaa"
	    	fill_in "location_name", :with => @location.name
	    	click_button I18n.t("button.add")

	    	audit_log = AuditLog.find_by_audit_target("location")
      		audit_log.should_not be_nil
      		audit_log.audit_target.should == "location"
      		audit_log.action_by.should == @root_user.employee_id
      		audit_log.action_type.should == "add"
      		audit_log.action.should == "add"
      		audit_log.action_status.should == "fail"
      		audit_log.action_error.should_not be_nil
      		audit_log.ip.should_not be_nil
      		audit_log.session_id.should_not be_nil
      		audit_log.description.should_not be_nil
	    end
	end

	describe '[21] Enable/Disable Location' do
		before(:each) do
	      clean_dbs
	      create_shift_data
	      mock_cage_info
	    end

	    after(:each) do
	      AuditLog.delete_all
	      Location.delete_all
	    end

	    it '[21.1] Enable location success' do
	    	@location = Location.create!(:name => "AAA", :status => "inactive")
	    	login_as_admin
	    	visit list_locations_path("active")
	    	click_link I18n.t("general.inactive")
	    	str = "#enable_location_" + @location.id.to_s
	    	find(str).click
	    	check_flash_message I18n.t("location.enable_success", name: @location.name.upcase)
	    end

	    it '[21.2] Enable location fail case' do
	    	@location = Location.create!(:name => "AAA", :status => "inactive")
	    	login_as_admin
	    	visit list_locations_path("active")
	    	click_link I18n.t("general.inactive")
	    	@location.status = "active"
	    	@location.save!
	    	str = "#enable_location_" + @location.id.to_s
	    	find(str).click
	    	check_flash_message I18n.t("location.already_enabled", name: @location.name.upcase)

	    end

	    it '[21.3] Disable location success' do
			@location = Location.create!(:name => "AAA", :status => "active")
	    	login_as_admin
	    	visit list_locations_path("active")
	    	str = "#disable_location_" + @location.id.to_s
	    	find(str).click
	    	check_flash_message I18n.t("location.disable_success", name: @location.name.upcase)
		end

		it '[21.4] Disable location with active station (fail)' do
			@location = Location.create!(:name => "AAA", :status => "active")
			@station = Station.create!(:name => "test_station", :location_id => @location.id, :status => "active" )
			login_as_admin
	    	visit list_locations_path("active")
	    	str = "#disable_location_" + @location.id.to_s
	    	find(str).click
	    	check_flash_message I18n.t("location.disable_fail")
	    	Station.delete_all
		end

		it '[21.5] Unauthorized enable/disable location' do

		end

		it '[21.6] Audit log for enable/disable location (success case)' do
			@location = Location.create!(:name => "AAA", :status => "inactive")
	    	login_as_admin
	    	visit list_locations_path("active")
	    	click_link I18n.t("general.inactive")
	    	str = "#enable_location_" + @location.id.to_s
	    	find(str).click
	    	check_flash_message I18n.t("location.enable_success", name: @location.name.upcase)

	    	audit_log = AuditLog.find_by_audit_target("location")
      		expect(audit_log).to_not be_nil
     		expect(audit_log.audit_target).to eq "location"
      		expect(audit_log.action_by).to eq @root_user.employee_id
      		expect(audit_log.action_type).to eq "update"
      		expect(audit_log.action).to eq "enable"
      		expect(audit_log.action_status).to eq "success"
      		expect(audit_log.action_error).to be_nil
      		expect(audit_log.ip).to_not be_nil
      		expect(audit_log.session_id).to_not be_nil
      		expect(audit_log.description).to_not be_nil

      		AuditLog.delete_all
	     	Location.delete_all

      		@location = Location.create!(:name => "BBB", :status => "active")
	    	visit list_locations_path("active")
	    	click_link I18n.t("general.active")
	    	str = "#disable_location_" + @location.id.to_s
	    	find(str).click
	    	check_flash_message I18n.t("location.disable_success", name: @location.name.upcase)

	    	audit_log = AuditLog.find_by_audit_target("location")
      		expect(audit_log).to_not be_nil
     		expect(audit_log.audit_target).to eq "location"
      		expect(audit_log.action_by).to eq @root_user.employee_id
      		expect(audit_log.action_type).to eq "update"
      		expect(audit_log.action).to eq "disable"
      		expect(audit_log.action_status).to eq "success"
      		expect(audit_log.action_error).to be_nil
      		expect(audit_log.ip).to_not be_nil
      		expect(audit_log.session_id).to_not be_nil
      		expect(audit_log.description).to_not be_nil
		end

		it '[21.7] Audit log for fail to enable/disable location' do
			@location = Location.create!(:name => "AAA", :status => "inactive")
	    	login_as_admin
	    	visit list_locations_path("active")
	    	click_link I18n.t("general.inactive")
	    	@location.status = "active"
	    	@location.save!
	    	str = "#enable_location_" + @location.id.to_s
	    	find(str).click
	    	check_flash_message I18n.t("location.already_enabled", name: @location.name.upcase)

	    	audit_log = AuditLog.find_by_audit_target("location")
      		expect(audit_log).to_not be_nil
     		expect(audit_log.audit_target).to eq "location"
      		expect(audit_log.action_by).to eq @root_user.employee_id
      		expect(audit_log.action_type).to eq "update"
      		expect(audit_log.action).to eq "enable"
      		expect(audit_log.action_status).to eq "fail"
      		expect(audit_log.action_error).to_not be_nil
      		expect(audit_log.ip).to_not be_nil
      		expect(audit_log.session_id).to_not be_nil
      		expect(audit_log.description).to_not be_nil

      		AuditLog.delete_all
	     	Location.delete_all

	     	@location = Location.create!(:name => "AAA", :status => "active")
			@station = Station.create!(:name => "test_station", :location_id => @location.id, :status => "active" )
	    	visit list_locations_path("active")
	    	str = "#disable_location_" + @location.id.to_s
	    	find(str).click
	    	check_flash_message I18n.t("location.disable_fail")
	    	Station.delete_all

	    	audit_log = AuditLog.find_by_audit_target("location")
      		expect(audit_log).to_not be_nil
     		expect(audit_log.audit_target).to eq "location"
      		expect(audit_log.action_by).to eq @root_user.employee_id
      		expect(audit_log.action_type).to eq "update"
      		expect(audit_log.action).to eq "disable"
      		expect(audit_log.action_status).to eq "fail"
      		expect(audit_log.action_error).to_not be_nil
      		expect(audit_log.ip).to_not be_nil
      		expect(audit_log.session_id).to_not be_nil
      		expect(audit_log.description).to_not be_nil
		end

	end



end
