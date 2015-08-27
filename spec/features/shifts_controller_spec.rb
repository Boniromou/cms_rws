require 'feature_spec_helper'

include FormattedTimeHelper

describe ShiftsController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  def get_next_shift_ac_date(current_shift, current_ac_date)
    shifts = ['morning', 'swing', 'night']
    next_shift = shifts.rotate[shifts.index(current_shift)]

    next_ac_date = current_ac_date
    next_ac_date += 1 if current_shift == 'night'

    [next_shift, next_ac_date]
  end

  def check_shift_content(current_shift, current_ac_date)
    next_shift, next_ac_date = get_next_shift_ac_date(current_shift, current_ac_date)

    expect(page).to have_content I18n.t("shift_name.#{current_shift}")
    expect(page).to have_content current_ac_date
    expect(page).to have_content I18n.t("shift_name.#{next_shift}")
    expect(page).to have_content next_ac_date
  end

  def check_breadcrumb( icon_style, title, subtitle )
    within("div#breadcrumbs h2") do
      expect(page).to have_content I18n.t(title) + " > " + I18n.t(subtitle)
      expect(page).to have_selector "i.#{icon_style.split.join('.')}"
    end
  end

  def roll_shift_and_check(current_shift, current_ac_date)
    visit shifts_path

    check_breadcrumb( "glyphicon glyphicon-retweet", "tree_panel.shift_management", "tree_panel.roll_shift" )
    expect(page).to have_content I18n.t("shift.current_shift")
    expect(page).to have_content I18n.t("shift.next_shift")
    expect(page).to have_button I18n.t("button.roll_shift_now")
    expect(find("div#confirm_roll_shift_dialog")[:style]).to include("none")

    check_shift_content(current_shift, current_ac_date)

    click_button I18n.t("button.roll_shift_now")
    expect(find("div#confirm_roll_shift_dialog")[:style]).to_not include("none")

    within("div#confirm_roll_shift_dialog") do
      expect(page).to have_content I18n.t("shift.confirm_roll_msg")

      expect(page).to have_button I18n.t("shift.confirm_roll_msg")
      expect(page).to have_selector "button#cancel"

      check_shift_content(current_shift, current_ac_date)

      click_button I18n.t("shift.confirm_roll_msg")
    end

    wait_for_ajax
  end

  def check_redirected_to_fm(pre_shift, pre_ac_date)
    check_breadcrumb( "glyphicon glyphicon-retweet", "tree_panel.shift_management", "tree_panel.front_money" )
    expect(page).to have_content I18n.t("shift.name")
    expect(page).to have_content I18n.t("ac_date.name")

    within("#search_form") do
      expect(page).to have_select('shift_name', selected: I18n.t("shift_name.#{pre_shift}"))
      expect(page).to have_selector("input#accounting_date[value='#{pre_ac_date}']")
    end
  end

  describe '[9] Roll shift' do
    before(:each) do
      clean_dbs
      create_shift_data

      @now = Time.now
      allow(Time).to receive(:now).and_return(@now)
    end

    it '[9.0] unauthorized roll shift redirect to home page' do
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:shfit,["roll"])

      visit home_path
      expect(page).to_not have_content I18n.t("tree_panel.roll_shift")

      visit shifts_path
      expect(page).to_not have_content I18n.t("tree_panel.roll_shift")
      check_home_page
    end

    it '[9.1] successfully roll shift (morning to swing)', js: true do
      login_as_admin

      roll_shift_and_check('morning', @today)
      check_flash_message(I18n.t("shift.roll_success", timestamp: format_time(@now)))

      check_redirected_to_fm('morning', @today)
    end
    
    it '[9.2] unauthorized roll shift' do
      @test_user = User.create!(:uid => 2, :name => 'test.user')
      login_as_not_admin(@test_user)
      set_permission(@test_user,"cashier",:shfit,["roll"])

      visit home_path
      expect(page).to_not have_content I18n.t("tree_panel.roll_shift")
    end

    it '[9.3] Audit log for roll shift', js: true do
      login_as_admin

      roll_shift_and_check('morning', @today)

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

    it '[9.4] successfully roll shift (night to morning)', js: true do
      login_as_admin

      roll_shift_and_check('morning', @today)
      check_flash_message(I18n.t("shift.roll_success", timestamp: format_time(@now)))
      check_redirected_to_fm('morning', @today)

      roll_shift_and_check('swing', @today)
      check_flash_message(I18n.t("shift.roll_success", timestamp: format_time(@now)))
      check_redirected_to_fm('swing', @today)

      roll_shift_and_check('night', @today)
      check_flash_message(I18n.t("shift.roll_success", timestamp: format_time(@now)))
      check_redirected_to_fm('night', @today)

      visit shifts_path
      check_shift_content('morning', @today + 1)
    end

    it '[9.5] Lock version for roll shift', js: true do
      fixed_shift = Shift.first
      allow_any_instance_of(ApplicationController).to receive(:current_shift).and_return(fixed_shift)

      login_as_admin

      roll_shift_and_check('morning', @today)
      check_flash_message(I18n.t("shift.roll_success", timestamp: format_time(@now)))

      roll_shift_and_check('morning', @today)
      check_flash_message(I18n.t("shift.rolled_error"))
    end

    it '[9.6] successfully roll shift (swing to night)', js: true do
      login_as_admin

      roll_shift_and_check('morning', @today)
      check_flash_message(I18n.t("shift.roll_success", timestamp: format_time(@now)))
      check_redirected_to_fm('morning', @today)

      roll_shift_and_check('swing', @today)
      check_flash_message(I18n.t("shift.roll_success", timestamp: format_time(@now)))
      check_redirected_to_fm('swing', @today)
    end
  end

  describe '[10] Update shift and account date to other windows' do
    before(:each) do
      clean_dbs
      create_shift_data

      allow_any_instance_of(CageInfoHelper).to receive(:polling_interval).and_return(100)
    end

    it '[10.1] Successfully update shift to other windows', js: true do
      login_as_admin
      roll_shift_and_check('morning', @today)

      next_shift, next_ac_date = get_next_shift_ac_date('morning', @today)

      sleep 4.seconds

      within("body header#header") do
        expect(page).to have_content I18n.t("shift_name.#{next_shift}")
        expect(page).to have_content next_ac_date
      end
    end
  end
end
