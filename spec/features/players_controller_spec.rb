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
      expect(page.source).to have_selector("form#new_player div input#player_player_name")
    end

    it '[3.2] Successfully create player' do
      login_as(@root_user)
      visit new_player_path
      @player = Player.new
      @player.member_id = 123456
      @player.player_name = "test player"
      fill_in "player_member_id", :with => @player.member_id
      fill_in "player_player_name", :with => @player.player_name
      click_button I18n.t("button.create")

      title = first("div div h1")
      expect(title.text).to eq I18n.t("tree_panel.balance")
      check_flash_message I18n.t("create_player.success")

      test_player = Player.find_by_member_id(@player.member_id)
      expect(test_player).not_to be_nil
      test_player.member_id = @player.member_id
      test_player.player_name = @player.player_name
    end
  end
end
