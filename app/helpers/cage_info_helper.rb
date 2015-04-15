module CageInfoHelper
  def current_cage_location
    "Main Cage - Window #1!!"
  end

  def current_accounting_date
    DateTime.now.strftime('%Y-%m-%d') + "!!!"
  end

  def current_shift
    shift = Shift.find_by_roll_shift_at(nil)
    shift_type = ShiftType.find_by_id(shift.shift_type_id)
    shift_type.name.capitalize + " Shift!!!"
  end
end
