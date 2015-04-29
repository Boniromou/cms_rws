require 'feature_spec_helper'

describe ShiftsController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[9] Roll shift' do
    def clean_dbs
      Shift.delete_all
      AccountingDate.delete_all
      ShiftType.delete_all
      User.delete_all
      Station.delete_all
      AuditLog.delete_all
    end

    before(:each) do
      clean_dbs

      @today = Date.today

      @shift_type_id = ShiftType.create!(:name => 'morning').id
      ShiftType.create!(:name => 'swing')
      ShiftType.create!(:name => 'night')

      @accounting_date_id = AccountingDate.create!(:accounting_date => @today).id

      Shift.create!(:shift_type_id => @shift_type_id, :accounting_date_id => @accounting_date_id)

      @station_id = Station.create!(:name => 'window#1').id
      allow_any_instance_of(ApplicationController).to receive(:current_station_id).and_return(@station_id)
    end

    it '[9.1] successfully roll shift (morning to swing)' do
      skip
    end
    
    it '[9.2] unauthorized roll shift' do
      skip
    end

    it '[9.3] Audit log for roll shift', js: true do
      login_as_admin

      visit shifts_path
      expect(find("div#confirm_roll_shift_dialog")[:style]).to include("none")

      click_button I18n.t("button.roll_shift_now")
      expect(find("div#confirm_roll_shift_dialog")[:style]).to_not include("none")

      within("div#confirm_roll_shift_dialog") do
        click_button I18n.t("button.confirm")
      end

      wait_for_ajax

      audit_log = AuditLog.find_by_audit_target("shift")
      audit_log.should_not be_nil
      audit_log.audit_target.should == "shift"
      audit_log.action_by.should == @root_user_name
      audit_log.action_type.should == "create"
      audit_log.action.should == "roll_shift"
      audit_log.action_status.should == "success"
      audit_log.action_error.should be_nil
      audit_log.ip.should_not be_nil
      audit_log.session_id.should_not be_nil
      audit_log.description.should_not be_nil
    end

    it '[9.4] successfully roll shift (night to morning)' do
      skip
    end

    it '[9.5] Lock version for roll shift' do
      skip
    end

    it '[9.6] successfully roll shift (swing to night)' do
      skip
    end
  end
end
