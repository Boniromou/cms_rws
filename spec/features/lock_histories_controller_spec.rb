require "feature_spec_helper"

describe LockHistoriesController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[46] Change log for lock/unlock player' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      mock_patron_not_change
      
      @player = Player.create!(:first_name => "test", :last_name => "player", :member_id => "123456", :card_id => "1234567890", :currency_id => 1, :status => "active")
      allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(0.0)
    end

    after(:each) do
      ChangeHistory.delete_all
      PlayersLockType.delete_all
      Player.delete_all
    end

    it '[46.1] Display lock player change log', :js => true do
      lock_or_unlock_player_and_check
      visit search_lock_histories_path
      check_search_ch_page
      find("input#search").click
      wait_for_ajax
      ch1 = ChangeHistory.find_by_object('player')
      check_ch_report_result_items([ch1])
    end

    it '[46.2] Display unlock player change log', :js => true do
      lock_or_unlock_player_and_check
      lock_or_unlock_player_and_check
      visit search_lock_histories_path
      check_search_ch_page
      find("input#search").click
      wait_for_ajax
      ch1 = ChangeHistory.all.first
      ch2 = ChangeHistory.all.last
      check_ch_report_result_items([ch1, ch2])
    end
  end
end
