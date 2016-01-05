module MockHelper
  def mock_time_at_now(time_in_str)
    fake_time = Time.parse(time_in_str)
    allow(Time).to receive(:now).and_return(fake_time)
  end

  def mock_cage_info
    @location = "N/A"
    @accounting_date = "2015-04-15"
    @shift = "morning"

    ac = AccountingDate.new
    ac.accounting_date = @accounting_date

    allow_any_instance_of(CageInfoHelper).to receive(:current_cage_location_str).and_return(@location)
    allow(AccountingDate).to receive(:current).and_return(ac)
    allow_any_instance_of(Shift).to receive(:name).and_return(@shift)
  end

  def mock_close_after_print
    allow_any_instance_of(PlayerTransactionsHelper).to receive(:is_close_after_print).and_return(false)
  end

  def mock_have_active_location
    allow_any_instance_of(ApplicationController).to receive(:have_active_location?).and_return(true)
  end

  def mock_have_machine_token
    allow_any_instance_of(UserSessionsController).to receive(:get_machine_token).and_return('20000|1|01|4|0102|2|abc1234|6e80a295eeff4554bf025098cca6eb37')
  end

  def mock_not_have_machine_token
    allow_any_instance_of(UserSessionsController).to receive(:get_machine_token).and_return(nil)
  end

  def mock_patron_not_change
    allow_any_instance_of(Requester::Patron).to receive(:get_player_info).and_return({:error_code => 'OK'})
  end

  def mock_receive_location_name
    allow_any_instance_of(Requester::Station).to receive(:validate_machine_token).and_return({:error_code => 'OK', :error_msg => 'Request is carried out successfully.', :location_name => '0102', :zone_name => '01'})
  end

  def mock_not_receive_location_name
    allow_any_instance_of(Requester::Station).to receive(:validate_machine_token).and_return({:location_name => nil})
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
    response = Requester::GetPlayerBalanceResponse.new({:error_code => 'OK', :balance => balance, :credit_balance => credit_balance, :credit_expired_at => credit_expired_at})
    allow_any_instance_of(Requester::Wallet).to receive(:get_player_balance).and_return(response)
  end

  def mock_current_property_id(property_id = 20000)
    allow_any_instance_of(ApplicationController).to receive(:current_property_id).and_return(property_id)
  end

  def mock_wallet_transaction_success(trans_type_sym)
    wallet_response = Requester::WalletTransactionResponse.new({:error_code => 'OK', :error_message => 'Request is carried out successfully.'})
    allow_any_instance_of(Requester::Wallet).to receive(trans_type_sym).and_return(wallet_response)
  end

  def mock_wallet_response_success(trans_type_sym)
    wallet_response = Requester::WalletResponse.new({:error_code => 'OK', :error_message => 'Request is carried out successfully.'})
    allow_any_instance_of(Requester::Wallet).to receive(trans_type_sym).and_return(wallet_response)
  end
end

RSpec.configure do |config|
  config.include MockHelper, type: :feature
end
