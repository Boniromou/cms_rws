require "feature_spec_helper"

describe PinHistoriesController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  describe '[55] Audit Log for MGM: Change PIN (Column: Staff, Time, Player, Action=Create/Reset)' do
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

    it '[55.1] Display create PIN audit log', :js => true do
      audit_log = {:user => 'portal.admin', :member_id => '88888888', :action => 'create', :action_at => '2015-01-01 00:00:00'}
      allow_any_instance_of(Requester::Patron).to receive(:get_pin_audit_logs).and_return([audit_log])
      lock_or_unlock_player_and_check
      visit search_pin_histories_path
      check_player_transaction_page_time_range_picker
      find("input#search").click
      wait_for_ajax
      check_ph_report_result_items([audit_log])
    end
  end
end