module ShiftHelper
  def clean_dbs
    PlayerTransaction.delete_all
    Shift.delete_all
    AccountingDate.delete_all
    PropertiesShiftType.delete_all
    ShiftType.delete_all
    User.delete_all
    Station.delete_all
    AuditLog.delete_all
    PlayersLockType.delete_all
    Player.delete_all
    Location.delete_all
  end

  def create_shift_data
    @today = Date.today
    @accounting_date = "2015-04-15"

    @moring_shift_type = ShiftType.create!(:name => 'morning')
    @swing_shift_type = ShiftType.create!(:name => 'swing')
    @night_shift_type = ShiftType.create!(:name => 'night')
    @day_shift_type = ShiftType.create!(:name => 'day')

    @shift_type_id = @moring_shift_type.id
    @accounting_date_id = AccountingDate.create!(:accounting_date => @accounting_date).id

    Shift.create!(:shift_type_id => @shift_type_id, :accounting_date_id => @accounting_date_id)

    # @station_id = Station.create!(:name => 'window#1').id
    # allow_any_instance_of(ApplicationController).to receive(:current_station_id).and_return(@station_id)
  end

  def create_moring_swing_night_shift_sequence
    PropertiesShiftType.create!(:property_id => 20000, :shift_type_id => @moring_shift_type.id, :sequence => 1)
    PropertiesShiftType.create!(:property_id => 20000, :shift_type_id => @swing_shift_type.id, :sequence => 2)
    PropertiesShiftType.create!(:property_id => 20000, :shift_type_id => @night_shift_type.id, :sequence => 3)
  end

end

RSpec.configure do |config|
  config.include ShiftHelper, type: :feature
end
