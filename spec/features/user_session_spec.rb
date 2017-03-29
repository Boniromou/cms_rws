require "feature_spec_helper"

describe UserSessionsController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  def login_by_front_page
    @root_user_name = 'portal.admin'
    @root_user_password = '123456'

    allow(UserManagement).to receive(:authenticate).and_return({'success' => true, 'system_user' => {'username' => @root_user_name, 'id' => 1}})
    allow_any_instance_of(ApplicationPolicy).to receive(:is_admin?).and_return(true)
    allow(User).to receive(:get_casino_ids_by_uid).and_return([20000])

    visit login_path
    fill_in "user_username", with: @root_user_name
    fill_in "user_password", with: @root_user_password
    click_button I18n.t("general.login")
  end

  describe '[1] Authentication' do
    before(:each) do
      mock_cage_info
    end

    it '[1.1] Cage login page' do
      visit root_path

      expect(page).to have_title I18n.t("title.title")
      expect(page).to have_selector "form header:contains(#{I18n.t('title.login_title')})"
      expect(page).to have_field "user_username"
      expect(page).to have_selector "label[for='user_#{I18n.t("user.user_name")}']"
      expect(page).to have_field "user_password"
      expect(page).to have_selector "label[for='user_#{I18n.t("user.password")}']"
      expect(page).to have_link I18n.t("general.signup")
    end

    it '[1.2] Redirect to User registration page' do
      visit login_path

      expect(page).to have_link I18n.t("general.signup")
      expect(find_link(I18n.t("general.signup"))[:href]).to eq SSO_URL + REGISTRATION_PATH + "?app=" + current_url
    end

    it '[1.3] Successfully login with role authorized' do
      login_by_front_page

      expect(current_path).to eq "/home"
    end

    it '[1.4] Successfully logout' do
      login_by_front_page

      expect(page).to have_link I18n.t("general.logout")
      click_link I18n.t("general.logout")

      expect(current_path).to eq "/login"
    end

    it '[1.6] login without role assigned' do
      allow(UserManagement).to receive(:authenticate).and_return({'success' => false, 'message' => "alert.account_no_role"})
      allow_any_instance_of(ApplicationPolicy).to receive(:is_admin?).and_return(false)

      visit login_path
      fill_in "user_username", with: @root_user_name
      fill_in "user_password", with: @root_user_password
      click_button I18n.t("general.login")

      expect(page).to have_content I18n.t("alert.account_no_role")
      expect(current_path).to eq "/login"
    end
  end

  describe '[2] Display information' do
    before(:each) do
      mock_cage_info
      mock_current_casino_id
    end

    it '[2.1] Show information', js: true do
      visit login_path

      within '#cage_info' do
        expect(page).to have_content @location
        expect(page).to have_content @accounting_date
        # expect(page).to have_content @shift.capitalize
        expect(page).to have_content /\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}/
        expect(page).to have_content @casino_name
      end
    end
  end

  describe '[80] Show Casino Name in Login Page' do
    before(:each) do
      mock_cage_info
      mock_current_casino_id
    end

    it '[80.1] show casino name in login page', js: true do
      mock_have_machine_token
      mock_receive_location_name
      visit login_path
      wait_for_ajax

      within '#cage_info' do
        expect(page).to have_content @location
        expect(page).to have_content @accounting_date
        # expect(page).to have_content @shift.capitalize
        expect(page).to have_content /\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}/
        expect(page).to have_content Casino.find_by_id(20000).name
      end
    end

    it '[80.2] Show casino name in login page without machine token', js: true do
      visit login_path

      within '#cage_info' do
        expect(page).to have_content @location
        expect(page).to have_content @accounting_date
        # expect(page).to have_content @shift.capitalize
        expect(page).to have_content /\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}/
        expect(page).to have_content @casino_name
      end
    end
  end

end
