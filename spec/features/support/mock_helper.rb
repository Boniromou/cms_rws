module MockHelper
  def mock_time_at_now(time_in_str)
    fake_time = Time.parse(time_in_str)
    allow(Time).to receive(:now).and_return(fake_time)
  end

  def mock_cage_info
    @location = "No location"
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

  def mock_have_valid_terminal_id
    allow_any_instance_of(UserSessionsController).to receive(:get_terminal_id).and_return('eb693ec8252cd630102fd0d0fb7c3485')
  end

  def mock_have_invalid_terminal_id
    allow_any_instance_of(UserSessionsController).to receive(:get_terminal_id).and_return('x')
  end

  def mock_not_have_terminal_id
    allow_any_instance_of(UserSessionsController).to receive(:get_terminal_id).and_return(nil)
  end
end

RSpec.configure do |config|
  config.include MockHelper, type: :feature
end
