module CageInfoHelper
  def current_cage_location_str
    current_station.capitalize
  end

  def current_accounting_date_str
    accounting_date = current_shift.accounting_date
    accounting_date.strftime('%Y-%m-%d')
  end

  def current_shift_str
    shift_type_name = current_shift.shift_type
    shift_type_name.capitalize + " Shift"
  end

  protected

  def current_station
    "window#1" + "!!!"
  end

  def current_shift
    shift = Shift.find_by_roll_shift_at(nil)
    shift = Shift.new unless shift
    shift
  end
end
