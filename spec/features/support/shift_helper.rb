module ShiftHelper
  def clean_dbs
    ChangeHistory.delete_all
    PlayerTransaction.delete_all
    Shift.delete_all
    AccountingDate.delete_all
    CasinosShiftType.delete_all
    ShiftType.delete_all
    User.delete_all
    AuditLog.delete_all
    PlayersLockType.delete_all
    Token.delete_all
    Player.delete_all
  end

  def create_shift_data
    @accounting_date = "2015-04-15"
    @today = Date.parse(@accounting_date)

    @moring_shift_type = ShiftType.create!(:name => 'morning')
    @swing_shift_type = ShiftType.create!(:name => 'swing')
    @night_shift_type = ShiftType.create!(:name => 'night')
    @day_shift_type = ShiftType.create!(:name => 'day')

    @accounting_date_id = AccountingDate.create!(:accounting_date => @accounting_date).id
    create_moring_swing_night_shift_sequence

    # @station_id = Station.create!(:name => 'window#1').id
    # allow_any_instance_of(ApplicationController).to receive(:current_station_id).and_return(@station_id)
  end

  def create_moring_swing_night_shift_sequence
    CasinosShiftType.create!(:casino_id => 20000, :shift_type_id => @moring_shift_type.id, :sequence => 1)
    CasinosShiftType.create!(:casino_id => 20000, :shift_type_id => @swing_shift_type.id, :sequence => 2)
    CasinosShiftType.create!(:casino_id => 20000, :shift_type_id => @night_shift_type.id, :sequence => 3)
    Shift.delete_all
    Shift.create!(:shift_type_id => @moring_shift_type.id, :accounting_date_id => @accounting_date_id, :casino_id => 20000)
  end
  
  def create_day_sequence
    CasinosShiftType.create!(:casino_id => 20000, :shift_type_id => @day_shift_type.id, :sequence => 1)
    Shift.delete_all
    Shift.create!(:shift_type_id => @day_shift_type.id, :accounting_date_id => @accounting_date_id, :casino_id => 20000)
  end

  def create_past_shift
    Shift.delete_all
    @past_accounting_date_id = AccountingDate.create!(:accounting_date => "2015-04-10").id
    @past_shift = Shift.create!(:shift_type_id => @moring_shift_type.id, :accounting_date_id => @past_accounting_date_id, :casino_id => 20000)
    Shift.create!(:shift_type_id => @moring_shift_type.id, :accounting_date_id => @accounting_date_id, :casino_id => 20000)
  end

end

RSpec.configure do |config|
  config.include ShiftHelper, type: :feature
end
