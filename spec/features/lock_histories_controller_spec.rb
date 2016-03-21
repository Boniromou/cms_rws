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
      
      @player = create_default_player
      mock_wallet_balance(0.0)
    end

    after(:each) do
      clean_dbs
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

  describe '[70]Show licensee lock player log with casino tool tip' do
    before(:each) do
      clean_dbs
      create_shift_data
      mock_cage_info
      mock_patron_not_change
      
      @player = create_default_player
      mock_wallet_balance(0.0)
    end

    after(:each) do
      clean_dbs
    end

    it '[70.1] Show licensee lock player log with casino tool tip', :js => true do
      lock_or_unlock_player_and_check
      lock_or_unlock_player_and_check
      lock_or_unlock_player_and_check
      lock_or_unlock_player_and_check
      ch1 = ChangeHistory.all.first
      ch2 = ChangeHistory.all[1]
      ch3 = ChangeHistory.all[2]
      ch4 = ChangeHistory.all[3]
      ch3.casino_id = 1003
      ch3.save!
      ch4.casino_id = 1003
      ch4.save!
      visit search_lock_histories_path
      check_search_ch_page
      find("input#search").click
      wait_for_ajax
      check_ch_report_result_items([ch1, ch2, ch3, ch4])
    end
  end
end
