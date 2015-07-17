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

    describe '[20] Add location' do
	    before(:each) do
	      clean_dbs
	      create_shift_data
	      mock_cage_info

	      allow_any_instance_of(Requester::Standard).to receive(:add_location).and_return('OK')
	    end

	    after(:each) do
	      AuditLog.delete_all
	      Location.delete_all
	    end

	    it '[20.1] Add location success' do
	    	login_as_admin
	    	visit list_locations_path("active")
	    	@location = Location.new
	    	@location.name = "test"
	    	fill_in "location_name", :with => @location.name
	    	click_button I18n.t("button.add")

	    	check_title("tree_panel.location")
	    	check_flash_message I18n.t("location.add_success", name: @location.name.upcase)

	    	test_location = Location.find_by_name(@location.name.upcase)
	    	expect(test_location).not_to be_nil
	    	test_location.name = @location.name
	    end
	end

end
