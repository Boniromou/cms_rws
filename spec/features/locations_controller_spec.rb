require "feature_spec_helper"

describe LocationsController do
	before(:all) do
    	include Warden::Test::Helpers
    	Warden.test_mode!
    	@root_user = User.create!(:uid => 1, :employee_id => 'portal.admin')
  	end

  	after(:all) do
    	Warden.test_reset!
  	end

  	describe '[19] List Active/Inactive location' do
		before(:each) do
	      clean_dbs
	      create_shift_data
	      mock_cage_info
	    end

	    after(:each) do
	      AuditLog.delete_all
	      Location.delete_all
	    end

	    it '[19.1] List active location' do
	    	@location1 = Location.create!(:name => "AAA", :status => "active")
	    	@location2 = Location.create!(:name => "BBB", :status => "active")
	    	str1 = "tr#location_" + @location1.id.to_s
	    	str2 = "tr#location_" + @location2.id.to_s
	    	login_as_admin
	    	visit home_path
	    	click_link I18n.t("tree_panel.location")
	    	check_title("tree_panel.location")
	    	expect(page.source).to have_selector("table#datatable_col_reorder")
	    	expect(page.source).to have_selector(str1)
	    	expect(page.source).to have_selector(str2)
		end

		it '[19.2] List inactive location' do
			@location1 = Location.create!(:name => "AAA", :status => "inactive")
			@location2 = Location.create!(:name => "BBB", :status => "inactive")
	    	str1 = "tr#location_" + @location1.id.to_s
	    	str2 = "tr#location_" + @location2.id.to_s
	    	login_as_admin
	    	visit home_path
	    	click_link I18n.t("tree_panel.location")
	    	check_title("tree_panel.location")
	    	click_link I18n.t("general.inactive")
	    	expect(page.source).to have_selector("table#datatable_col_reorder")
	    	expect(page.source).to have_selector(str1)
	    	expect(page.source).to have_selector(str2)
		end

		it '[19.3] Unauthorized list active/inactive location', js: true do
			@test_user = User.create!(:uid => 2, :employee_id => 'test.user')
			login_as_not_admin(@test_user)
			set_permission(@test_user,"cashier",:location,[])
			visit list_locations_path("active")
      		wait_for_ajax
      		check_home_page
      		check_flash_message I18n.t("flash_message.not_authorize")
			User.delete_all

		end

		it '[19.4] Click link to the list location page', js: true do
			@test_user = User.create!(:uid => 2, :employee_id => 'test.user')
      		login_as_not_admin(@test_user)
      		set_permission(@test_user,"cashier",:player,[])
      		visit list_locations_path("active")
      		wait_for_ajax
      		check_home_page
      		check_flash_message I18n.t("flash_message.not_authorize")
      		User.delete_all
		end

  	end

    describe '[20] Add location' do
	    before(:each) do
	      clean_dbs
	      create_shift_data
	      mock_cage_info
	    end

	    after(:each) do
	      AuditLog.delete_all
	      Location.delete_all
	    end

	    it '[20.1] Add location success', :js => true do
	    	login_as_admin
	    	visit list_locations_path("active")
	    	@location = Location.new
	    	@location.name = "test"
	    	fill_in "name", :with => @location.name

	    	content_list = [I18n.t("confirm_box.add_location"), @location.name]
     		click_pop_up_confirm("add_location_confirm", content_list)

	    	check_title("tree_panel.location")
	    	check_flash_message I18n.t("location.add_success", name: @location.name.upcase)

	    	test_location = Location.find_by_name(@location.name.upcase)
	    	expect(test_location).not_to be_nil
	    	test_location.name = @location.name
	    end

	    it '[20.2] Duplicate location name', :js => true do
	    	Location.create!(:name => "AAA", :status => "active")
	    	login_as_admin
	    	visit list_locations_path("active")
	    	@location = Location.new
	    	@location.name = "aaa"
	    	fill_in "name", :with => @location.name

	    	content_list = [I18n.t("confirm_box.add_location"), @location.name]
     		click_pop_up_confirm("add_location_confirm", content_list)

	    	check_title("tree_panel.location")
	    	check_flash_message I18n.t("location.already_existed", name: @location.name.upcase)
	    end

	    it '[20.3] Add location with no location name', :js => true do
	    	login_as_admin
	    	visit list_locations_path("active")
	    	@location = Location.new
	    	@location.name = " "
	    	fill_in "name", :with => @location.name
	    	expect(find("#add_location_confirm")[:class]).to eq "btn btn-primary disabled"	    	
	    end

	    it '[20.4] Unauthorized add location' do
	    	User.delete_all
	    	@test_user = User.create!(:uid => 2, :employee_id => 'test.user')
			set_permission(@test_user,"cashier",:location, ["list"])
			login_as_not_admin(@test_user)
			visit home_path
			click_link I18n.t("tree_panel.location")
			check_title("tree_panel.location")
	    	expect(page.source).to have_selector("table#datatable_col_reorder")
			expect(page.source).to_not have_selector("input#name")
			expect(page.source).to_not have_selector("input#add_location_confirm")
			User.delete_all
	    end

	    it '[20.5] Audit log for add location', :js => true do
	    	login_as_admin
	    	visit list_locations_path("active")
	    	@location = Location.new
	    	@location.name = "test"
	    	fill_in "name", :with => @location.name
	    	
	    	content_list = [I18n.t("confirm_box.add_location"), @location.name]
     		click_pop_up_confirm("add_location_confirm", content_list)
     		wait_for_ajax

	    	audit_log = AuditLog.find_by_audit_target("location")
      		audit_log.should_not be_nil
      		audit_log.audit_target.should == "location"
      		audit_log.action_by.should == @root_user.employee_id
      		audit_log.action_type.should == "create"
      		audit_log.action.should == "add"
      		audit_log.action_status.should == "success"
      		audit_log.action_error.should be_nil
      		audit_log.ip.should_not be_nil
      		audit_log.session_id.should_not be_nil
      		audit_log.description.should_not be_nil
	    end

	    it '[20.6] Audit log for fail to add location', :js => true do
	    	Location.create!(:name => "AAA", :status => "active")
	    	login_as_admin
	    	visit list_locations_path("active")
	    	@location = Location.new
	    	@location.name = "aaa"
	    	fill_in "name", :with => @location.name
	    	
	    	content_list = [I18n.t("confirm_box.add_location"), @location.name]
     		click_pop_up_confirm("add_location_confirm", content_list)
     		wait_for_ajax

	    	audit_log = AuditLog.find_by_audit_target("location")
      		audit_log.should_not be_nil
      		audit_log.audit_target.should == "location"
      		audit_log.action_by.should == @root_user.employee_id
      		audit_log.action_type.should == "create"
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
	      Location.delete_all
	    end

	    after(:each) do
	      AuditLog.delete_all
	      Location.delete_all
	    end

	    it '[21.1] Enable location success', :js => true  do
	    	@location = Location.create!(:name => "AAA", :status => "inactive")
	    	login_as_admin
	    	visit list_locations_path("active")
	    	click_link I18n.t("general.inactive")	    	

	    	content_list = [I18n.t("confirm_box.enable_location", {:name => @location.name.upcase })]
     		click_pop_up_confirm("change_location_status_#{@location.id.to_s}", content_list)
     		wait_for_ajax

	    	check_flash_message I18n.t("location.enable_success", name: @location.name.upcase)
	    end

	    it '[21.2] Enable location fail case', :js => true do
	    	@location = Location.create!(:name => "AAA", :status => "inactive")
	    	login_as_admin
	    	visit list_locations_path("active")
	    	click_link I18n.t("general.inactive")
	    	wait_for_ajax
	    	@location.status = "active"
	    	@location.save!

	    	content_list = [I18n.t("confirm_box.enable_location", {:name => @location.name.upcase })]
     	 	click_pop_up_confirm("change_location_status_#{@location.id.to_s}", content_list)
     	 	wait_for_ajax

	    	check_flash_message I18n.t("location.already_enabled", name: @location.name.upcase)
	    end

	    it '[21.3] Disable location success', :js => true do
			@location = Location.create!(:name => "AAA", :status => "active")
	    	login_as_admin
	    	visit list_locations_path("active")
	    	
	    	content_list = [I18n.t("confirm_box.disable_location", {:name => @location.name.upcase })]
     		click_pop_up_confirm("change_location_status_#{@location.id.to_s}", content_list)
     		wait_for_ajax

	    	check_flash_message I18n.t("location.disable_success", name: @location.name.upcase)
		end

		it '[21.4] Disable location with active station (fail)', :js => true do
			@location = Location.create!(:name => "AAA", :status => "active")
			@station = Station.create!(:name => "test_station", :location_id => @location.id, :status => "active" )
			login_as_admin
	    	visit list_locations_path("active")
	    	
	    	content_list = [I18n.t("confirm_box.disable_location", {:name => @location.name.upcase })]
     		click_pop_up_confirm("change_location_status_#{@location.id.to_s}", content_list)
     		wait_for_ajax

	    	check_flash_message I18n.t("location.disable_fail")
	    	Station.delete_all
		end

		it '[21.5] Unauthorized enable/disable location' do
			User.delete_all
	    	@test_user = User.create!(:uid => 2, :employee_id => 'test.user')
	    	@location = Location.create!(:name => "AAA", :status => "inactive")
			set_permission(@test_user,"cashier",:location, ["list"])
			login_as_not_admin(@test_user)
			visit home_path
			click_link I18n.t("tree_panel.location")
			check_title("tree_panel.location")
	    	expect(page.source).to have_selector("table#datatable_col_reorder")
			expect(page.source).to_not have_selector("input#name")
			expect(page.source).to_not have_selector("input#add_location_confirm")
			expect(page.source).to_not have_selector("button#change_location_status_#{@location.id.to_s}")
			User.delete_all
		end

		it '[21.6] Audit log for enable location (success case)', :js => true do
			@location = Location.create!(:name => "AAA", :status => "inactive")
	    	login_as_admin
	    	visit list_locations_path("active")
	    	click_link I18n.t("general.inactive")
	    	
	    	content_list = [I18n.t("confirm_box.enable_location", {:name => @location.name.upcase })]
     		click_pop_up_confirm("change_location_status_#{@location.id.to_s}", content_list)
     		wait_for_ajax

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

      	end

      	it '[21.8] Audit log for disable location (success case)', :js => true do

      		@location = Location.create!(:name => "BBB", :status => "active")
      		login_as_admin
	    	visit list_locations_path("active")
	    	
			content_list = [I18n.t("confirm_box.disable_location", {:name => @location.name.upcase })]
     		click_pop_up_confirm("change_location_status_#{@location.id.to_s}", content_list)
     		wait_for_ajax

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

		it '[21.7] Audit log for fail to enable location', :js => true do
			@location = Location.create!(:name => "AAA", :status => "inactive")
	    	login_as_admin
	    	visit list_locations_path("active")
	    	click_link I18n.t("general.inactive")
	    	wait_for_ajax
	    	@location.status = "active"
	    	@location.save!
	    	
			content_list = [I18n.t("confirm_box.enable_location", {:name => @location.name.upcase })]
     		click_pop_up_confirm("change_location_status_#{@location.id.to_s}", content_list)
     		wait_for_ajax


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
      	end

      	it '[21.9] Audit log for fail to disable location', :js => true do

	     	@location = Location.create!(:name => "AAA", :status => "active")
			@station = Station.create!(:name => "test_station", :location_id => @location.id, :status => "active" )
	    	login_as_admin
	    	visit list_locations_path("active")

	    	content_list = [I18n.t("confirm_box.disable_location", {:name => @location.name.upcase })]
     		click_pop_up_confirm("change_location_status_#{@location.id.to_s}", content_list)
     		wait_for_ajax

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
