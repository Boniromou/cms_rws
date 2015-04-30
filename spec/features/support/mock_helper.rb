module MockHelper
  def mock_time_at_now(time_in_str)
    fake_time = Time.parse(time_in_str)
    allow(Time).to receive(:now).and_return(fake_time)
  end

  def mock_cage_info
    @location = "Main Cage - Window #1"
    @accounting_date = "2015-04-15"
    @shift = "morning"

    ac = AccountingDate.new
    ac.accounting_date = @accounting_date

    allow_any_instance_of(CageInfoHelper).to receive(:current_cage_location_str).and_return(@location)
    allow(AccountingDate).to receive(:current).and_return(ac)
    allow_any_instance_of(Shift).to receive(:name).and_return(@shift)
  end
end

RSpec.configure do |config|
  config.include MockHelper, type: :feature
end