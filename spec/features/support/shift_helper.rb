module ShiftHelper
  def clean_dbs
    PlayerTransaction.delete_all
    Shift.delete_all
    AccountingDate.delete_all
    ShiftType.delete_all
    User.delete_all
    Station.delete_all
    AuditLog.delete_all
    Player.delete_all
  end

  def create_shift_data
    @today = Date.today

    @shift_type_id = ShiftType.create!(:name => 'morning').id
    ShiftType.create!(:name => 'swing')
    ShiftType.create!(:name => 'night')

    @accounting_date_id = AccountingDate.create!(:accounting_date => @today).id

    Shift.create!(:shift_type_id => @shift_type_id, :accounting_date_id => @accounting_date_id)

    @station_id = Station.create!(:name => 'window#1').id
    allow_any_instance_of(ApplicationController).to receive(:current_station_id).and_return(@station_id)
  end

end

RSpec.configure do |config|
  config.include ShiftHelper, type: :feature
end
