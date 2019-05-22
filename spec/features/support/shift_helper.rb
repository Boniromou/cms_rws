module ShiftHelper
  def clean_dbs
    ChangeHistory.delete_all
    PlayerTransaction.delete_all
    KioskTransaction.delete_all
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

  def create_shift_data_multi
    #not work
    @accounting_date = Time.now.strftime("%Y-%m-%d")
    @today = Date.parse(@accounting_date)

    @moring_shift_type = ShiftType.create!(:name => 'morning1')
    @swing_shift_type = ShiftType.create!(:name => 'swing2')
    @night_shift_type = ShiftType.create!(:name => 'night3')

    @accounting_date_id = AccountingDate.create!(:accounting_date => @accounting_date).id
    create_moring_swing_night_shift_sequence_multi
  end

  def create_moring_swing_night_shift_sequence_multi
    CasinosShiftType.create!(:casino_id => 1003, :shift_type_id => @moring_shift_type.id, :sequence => 1)
    CasinosShiftType.create!(:casino_id => 1003, :shift_type_id => @swing_shift_type.id, :sequence => 2)
    CasinosShiftType.create!(:casino_id => 1003, :shift_type_id => @night_shift_type.id, :sequence => 3)
    Shift.delete_all
    Shift.create!(:shift_type_id => @moring_shift_type.id, :accounting_date_id => @accounting_date_id, :casino_id => 1003)
  end

  def create_shift_data( return_which = 20000 )
    @accounting_date = Time.now.strftime("%Y-%m-%d")
    @today = Date.parse(@accounting_date)

    @moring_shift_type = ShiftType.where(:name => 'morning').first_or_create
    @swing_shift_type = ShiftType.where(:name => 'swing').first_or_create
    @night_shift_type = ShiftType.where(:name => 'night').first_or_create

    @accounting_date_id = AccountingDate.where(:accounting_date => @accounting_date).first_or_create.id
    create_moring_swing_night_shift_sequence( return_which )

    # @station_id = Station.create!(:name => 'window#1').id
    # allow_any_instance_of(ApplicationController).to receive(:current_station_id).and_return(@station_id)
  end

  def create_moring_swing_night_shift_sequence( return_which )
    CasinosShiftType.where(:casino_id => 20000, :shift_type_id => @moring_shift_type.id, :sequence => 1).first_or_create
    CasinosShiftType.where(:casino_id => 20000, :shift_type_id => @swing_shift_type.id, :sequence => 2).first_or_create
    CasinosShiftType.where(:casino_id => 20000, :shift_type_id => @night_shift_type.id, :sequence => 3).first_or_create
    CasinosShiftType.where(:casino_id => 10010, :shift_type_id => @moring_shift_type.id, :sequence => 1).first_or_create
    CasinosShiftType.where(:casino_id => 10010, :shift_type_id => @swing_shift_type.id, :sequence => 2).first_or_create
    CasinosShiftType.where(:casino_id => 10010, :shift_type_id => @night_shift_type.id, :sequence => 3).first_or_create
    Shift.delete_all

    if return_which == 10010
      Shift.where(:shift_type_id => @moring_shift_type.id, :accounting_date_id => @accounting_date_id, :casino_id => 20000).first_or_create
      Shift.where(:shift_type_id => @moring_shift_type.id, :accounting_date_id => @accounting_date_id, :casino_id => 10010).first_or_create
    else
      Shift.where(:shift_type_id => @moring_shift_type.id, :accounting_date_id => @accounting_date_id, :casino_id => 10010).first_or_create
      Shift.where(:shift_type_id => @moring_shift_type.id, :accounting_date_id => @accounting_date_id, :casino_id => 20000).first_or_create
    end
  end

  def create_past_shift
    Shift.delete_all
    @past_accounting_date_id = AccountingDate.create!(:accounting_date => (Time.now - 5.day).strftime("%Y-%m-%d")).id
    @past_shift = Shift.create!(:shift_type_id => @moring_shift_type.id, :accounting_date_id => @past_accounting_date_id, :casino_id => 20000)
    sleep 1
    Shift.create!(:shift_type_id => @moring_shift_type.id, :accounting_date_id => @accounting_date_id, :casino_id => 20000)
  end

end

RSpec.configure do |config|
  config.include ShiftHelper, type: :feature
  config.include ShiftHelper, type: :controller
end
