require "feature_spec_helper"
require "rails_helper"

describe MachinesController do
	describe '[43] Call Get Station Info API' do
	    before(:each) do
	      clean_dbs
	      create_shift_data
      	  mock_cage_info
	    end

	    after(:each) do
	      clean_dbs
	    end

	    it '[43.1] Launch Cage machine token not exist', :js => true do
	      mock_not_have_machine_token
	      visit root_path
	      within '#cage_info' do
	        expect(page).to have_content @location
	        check_location_name 'N/A'
	        expect(page).to have_content 'Waiting for accounting date'
	        expect(page).to have_content /\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}/
      	  end
	    end

	    it '[43.2] Launch Cage Get station info success', :js => true do
	      mock_have_machine_token
	      mock_receive_location_name
	      visit root_path
	      within '#cage_info' do
	        check_location_name '01/0102'
	        expect(page).to have_content 'Waiting for accounting date'
	        expect(page).to have_content /\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}/
      	  end
	    end

	    it '[43.3] Launch Cage Get station info fail', :js => true do
	      mock_have_machine_token
	      mock_not_receive_location_name
	      visit root_path
	      within '#cage_info' do
	        check_location_name 'N/A'
	        expect(page).to have_content 'Waiting for accounting date'
	        expect(page).to have_content /\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}/
      	  end
	    end

	    it '[43.4] Login Cage machine token not exist', :js => true do
	      mock_not_have_machine_token
	      login_as_admin
	      visit home_path
	       within 'header#header' do
	        check_location_name 'N/A'
	        expect(page).to have_content @accounting_date
	        expect(page).to have_content @shift.capitalize
	        expect(page).to have_content /\d{4}-\d{2}-\d{2}/
      	  end
	    end

	    it '[43.5] Login Cage Get station info success', :js => true do
	      mock_have_machine_token
	      mock_receive_location_name
	      login_as_admin_new
	       within 'header#header' do
	        check_location_name '01/0102'
	        expect(page).to have_content @accounting_date
	        expect(page).to have_content @shift.capitalize
	        expect(page).to have_content /\d{4}-\d{2}-\d{2}/
      	  end
	    end

	    it '[43.6] Login Cage Get station info fail', :js => true do
	      mock_have_machine_token
	      mock_not_receive_location_name
	      login_as_admin_new
	       within 'header#header' do
	        check_location_name 'N/A'
	        expect(page).to have_content @accounting_date
	        expect(page).to have_content @shift.capitalize
	        expect(page).to have_content /\d{4}-\d{2}-\d{2}/
      		end
		end
  	end
end
