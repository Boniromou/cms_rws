require "feature_spec_helper"

describe PlayersController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
    User.delete_all
    @root_user = User.create!(:uid => 1, :employee_id => 'portal.admin')
  end

  after(:all) do
    User.lelete_all
    Warden.test_reset!
  end

  describe '[3] Create player' do
    before(:each) do
      Player.delete_all
    end

    after(:each) do
      Player.delete_all
    end

    it '[3.1] Show Create Player Page' do
      login_as(@root_user)
      visit home_path
      click_link I18n.t("tree_panel.create_player")
      title = first("div div h1")
      expect(title.text).to eq I18n.t("tree_panel.create_player")
      expect(page.source).to have_selector("form#new_player div input#player_member_id")
      expect(page.source).to have_selector("form#new_player div input#player_name")
    end
  end
end
