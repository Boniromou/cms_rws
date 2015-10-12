require "feature_spec_helper"
require "rails_helper"

describe TerminalsController do
	describe '[43] Call Get Station Info API' do
	    before(:each) do
	      clean_dbs
	      create_shift_data
      	  mock_cage_info
	    end

	    after(:each) do
	      clean_dbs
	    end

	    it '[43.1] Launch Cage Terminal ID not exist OK', :js => true do
	      mock_not_have_terminal_id
	      visit root_path
	      within '#cage_info' do
	        expect(page).to have_content @location
	        @location.should == 'No location'
	        expect(page).to have_content @accounting_date
	        expect(page).to have_content /\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}/
      	  end
	    end

	    it '[43.2] Launch Cage Get station info success OK', :js => true do
	      mock_have_valid_terminal_id
	      visit root_path
	      within '#cage_info' do
	        check_location_name 'LOCATION10-STATION10'
	        expect(page).to have_content @accounting_date
	        expect(page).to have_content /\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}/
      	  end
	    end

	    it '[43.3] Launch Cage Get station info fail OK', :js => true do
	      mock_have_invalid_terminal_id
	      visit root_path
	      within '#cage_info' do
	        check_location_name 'No location'
	        expect(page).to have_content @accounting_date
	        expect(page).to have_content /\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}/
      	  end
	    end

	    it '[43.4] Login Cage Terminal ID not exist OK', :js => true do
	      mock_not_have_terminal_id
	      login_as_admin
	      visit home_path
	       within 'header#header' do
	        check_location_name 'No location'
	        expect(page).to have_content @accounting_date
	        expect(page).to have_content @shift.capitalize
	        expect(page).to have_content /\d{4}-\d{2}-\d{2}/
      	  end
	    end

	    it '[43.5] Login Cage Get station info success', :js => true do
	      mock_have_valid_terminal_id
	      login_as_admin_new
	       within 'header#header' do
	        check_location_name 'LOCATION10-STATION10'
	        expect(page).to have_content @accounting_date
	        expect(page).to have_content @shift.capitalize
	        expect(page).to have_content /\d{4}-\d{2}-\d{2}/
      	  end
	    end

	    it '[43.6] Login Cage Get station info fail', :js => true do
	      mock_have_invalid_terminal_id
	      login_as_admin_new
	       within 'header#header' do
	        check_location_name 'No location'
	        expect(page).to have_content @accounting_date
	        expect(page).to have_content @shift.capitalize
	        expect(page).to have_content /\d{4}-\d{2}-\d{2}/
      		end
		end
  	end
end