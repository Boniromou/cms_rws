module MockHelper
  def mock_time_at_now(time_in_str)
    fake_time = Time.parse(time_in_str)
    allow(Time).to receive(:now).and_return(fake_time)
  end

  def mock_cage_info
    @location = "---"
    @accounting_date = Time.now.strftime("%Y-%m-%d")
    @casino_name = "---"
    @shift = "morning"

    allow_any_instance_of(ApplicationController).to receive(:current_machine_token).and_return('|71|NielVIPcage|78|VIP01|54|machine1|ea0ba6020ea95930e3a46399b9fc42e2|20000')
    allow_any_instance_of(CageInfoHelper).to receive(:current_cage_location_str).and_return(@location)
    allow_any_instance_of(Shift).to receive(:name).and_return(@shift)
  end

  def mock_close_after_print
    allow_any_instance_of(PlayerTransactionsHelper).to receive(:is_close_after_print).and_return(false)
  end

  def mock_have_active_location
    allow_any_instance_of(ApplicationController).to receive(:have_active_location?).and_return(true)
  end

  def mock_have_machine_token
    allow_any_instance_of(UserSessionsController).to receive(:get_machine_token).and_return('|1|01|4|0102|2|abc1234|6e80a295eeff4554bf025098cca6eb37|20000')
  end

  def mock_not_have_machine_token
    allow_any_instance_of(UserSessionsController).to receive(:get_machine_token).and_return(nil)
  end

  def mock_patron_not_change
    mock_player_info_result({:error_code => 'OK'})
  end

  def mock_receive_location_name
    allow_any_instance_of(Requester::Station).to receive(:validate_machine_token).and_return(Requester::StationResponse.new({:error_code => 'OK', :error_msg => 'Request is carried out successfully.', :location_name => '0102', :zone_name => '01', :casino_id => 20000}))
  end

  def mock_not_receive_location_name
    allow_any_instance_of(Requester::Station).to receive(:validate_machine_token).and_return(Requester::StationResponse.new({:location_name => nil}))
  end

  def mock_current_machine_token
    allow_any_instance_of(ApplicationController).to receive(:current_machine_token).and_return('20000|1|01|4|0102|2|abc1234|6e80a295eeff4554bf025098cca6eb37')
  end

  def mock_wallet_balance(balance, credit_balance = nil, credit_expired_at = nil)
    balance = nil if balance == 'no_balance'
    credit_balance = nil if credit_balance == 'no_balance'
    credit_balance = 0.0 if !balance.nil? && credit_balance.nil?
    if credit_balance.nil? || credit_balance == 0
      credit_expired_at = nil
    else
      credit_expired_at ||= (Time.now + 2.day).strftime("%Y-%m-%d %H:%M:%S")
    end
    response = Requester::GetPlayerBalanceResponse.new({:error_code => 'OK', :balance => balance, :credit_balance => credit_balance, :credit_expired_at => credit_expired_at.to_s})
    allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(response)
  end

  def mock_account_activities(transactions = [], type = 'cage')
    response = Requester::GetAccountActivityResponse.new({:error_code => 'OK', :transactions => transactions})
    type = type == 'cage' ? 'Wallet' : 'MarketingWallet'
    allow_any_instance_of("Requester::#{type}".constantize).to receive(:get_account_activity).and_return(response)
  end

  def mock_account_activities_failed(type = 'cage')
    response = Requester::NoAccountActivityResponse.new
    type = type == 'cage' ? 'Wallet' : 'MarketingWallet'
    allow_any_instance_of("Requester::#{type}".constantize).to receive(:get_account_activity).and_return(response)
  end

  def mock_player_balances(players = [])
    response = Requester::GetPlayerBalancesResponse.new({:error_code => 'OK', :players => players})
    allow_any_instance_of(Requester::Wallet).to receive(:get_player_balances).and_return(response)
  end

  def mock_player_balances_failed
    response = Requester::GetPlayerBalancesResponse.new({:error_code => 'Error'})
    allow_any_instance_of(Requester::Wallet).to receive(:get_player_balances).and_return(response)
  end

  def mock_total_balances(player_size = 10, total_balances = 3000.13, total_credit_balances = 20.10)
    result = {:error_code => 'OK', :player_size => player_size, :total_balances => total_balances, :total_credit_balances => total_credit_balances }
    response = Requester::GetTotalBalancesResponse.new(result)
    allow_any_instance_of(Requester::Wallet).to receive(:get_total_balances).and_return(response)
  end

  def mock_total_balances_failed
    response = Requester::GetTotalBalancesResponse.new({:error_code => 'Error'})
    allow_any_instance_of(Requester::Wallet).to receive(:get_total_balances).and_return(response)
  end

  def mock_current_casino_id(casino_id = 20000)
    allow_any_instance_of(ApplicationController).to receive(:current_casino_id).and_return(casino_id)
  end

  def mock_wallet_transaction_success(trans_type_sym)
    wallet_response = Requester::WalletTransactionResponse.new({:error_code => 'OK', :error_message => 'Request is carried out successfully.', :trans_date => (Time.now + 5.second).strftime("%Y-%m-%d %H:%M:%S")})
    allow_any_instance_of(Requester::Wallet).to receive(trans_type_sym).and_return(wallet_response)
  end

  def mock_wallet_response_success(trans_type_sym)
    wallet_response = Requester::WalletResponse.new({:error_code => 'OK', :error_message => 'Request is carried out successfully.'})
    allow_any_instance_of(Requester::Wallet).to receive(trans_type_sym).and_return(wallet_response)
  end

  def mock_player_info_result(result_hash)
    patron_response = Requester::PlayerInfoResponse.new(result_hash)
    allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return(patron_response)
  end

  def mock_reset_pin_result(result_hash)
    patron_response = Requester::PlayerInfoResponse.new(result_hash)
    allow_any_instance_of(Requester::Patron).to receive(:reset_pin).and_return(patron_response)
  end

  def mock_permission_value(value)
    allow_any_instance_of(User).to receive(:get_permission_value).and_return(value)
  end

  def mock_configuration(name, value)
    allow_any_instance_of(ConfigHelper).to receive(name).and_return(value)
  end
end

RSpec.configure do |config|
  config.include MockHelper, type: :feature
end
