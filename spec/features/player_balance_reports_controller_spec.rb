require "feature_spec_helper"

describe PlayerBalanceReportsController do
  before(:all) do
    include Warden::Test::Helpers
    Warden.test_mode!
  end

  after(:all) do
    Warden.test_reset!
  end

  def check_player_balance_report_data(lock_types = '', balance = 500.0)
    values = [@player.member_id, @player.status.titleize, lock_types, display_balance(balance)]
    within('div#content table#player_balance_report_datatable tbody tr:nth-child(1)') do
      values.each_with_index do |td, td_index|
        expect(find("td:nth-child(#{td_index+1})").text).to eq td.to_s
      end
    end
  end

  describe 'Search Player Balance Report', js: true do
    before(:each) do
      mock_current_casino_id
      mock_total_balances
      @player = create_default_player
    end

    it 'show player balance report page' do
      mock_player_balances
      login_as_admin
      go_to_player_balance_report_page
      within('#player_balance_report_info') { expect(page).to have_content "#{I18n.t("general.total_balances")}: #{I18n.t("general.hkd")} #{display_balance(3000.13)}"  }
    end

    it 'show player balance report data' do
      players = [{'login_name'=>@player.member_id, 'balance'=>500.0, 'credit_balance'=>0.0, 'credit_expired_at'=>nil, 'credit_is_expired'=>false}]
      mock_player_balances(players)
      login_as_admin
      go_to_player_balance_report_page
      check_player_balance_report_data
    end

    it 'unauthorized player balance report' do
      login_as_test_user
      visit home_path
      expect(first("aside#left-panel ul li#nav_player_balance_report")).to eq nil
    end
  end
end
