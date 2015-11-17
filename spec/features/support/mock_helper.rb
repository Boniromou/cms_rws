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

  def mock_have_enable_station
    allow_any_instance_of(ApplicationController).to receive(:is_have_enable_station).and_return(true)
  end

  def mock_not_have_enable_station
    allow_any_instance_of(ApplicationController).to receive(:is_have_enable_station).and_return(false)
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
end

RSpec.configure do |config|
  config.include MockHelper, type: :feature
end
