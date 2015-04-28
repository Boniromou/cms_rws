class Shift < ActiveRecord::Base
  attr_accessible :shift_type_id, :roll_shift_by_user_id, :roll_shift_on_station_id, :accounting_date_id, :roll_shift_at
  
  def name
    ShiftType.get_name_by_id(shift_type_id)
  end

  def accounting_date
    AccountingDate.find_by_id(accounting_date_id).accounting_date
  end

  def roll!(station_id, user_id)
    raise 'Shift has been rolled!' if self.roll_shift_at != nil

    self.roll_shift_on_station_id = station_id
    self.roll_shift_by_user_id = user_id
    self.roll_shift_at = Time.now.utc

    new_shift = Shift.new
    new_shift_name = self.class.next_shift_name_by_name(name)
    new_shift.shift_type_id = ShiftType.get_id_by_name(new_shift_name)
    new_shift.accounting_date_id = AccountingDate.next_shift_accounting_date_id(name)

    Shift.transaction do
      self.save
      new_shift.save
    end
  end

  class << self
    SHIFT_NAME = %w(morning swing night)

    def current
      shift = Shift.find_by_roll_shift_at(nil)
      raise 'Current shift not found!' unless shift
      shift
    end

    def next_shift_name_by_name( shift_name )
      raise 'Shift name not found!!' if SHIFT_NAME.index(shift_name).nil?
      SHIFT_NAME[(SHIFT_NAME.index(shift_name) + 1) % 3]
    end
  end
end
