class Shift < ActiveRecord::Base
  attr_accessible :shift_type_id, :roll_shift_by_user_id, :roll_shift_on_station_id, :accounting_date_id, :roll_shift_at
  
  def name
    ShiftType.get_name_by_id(shift_type_id)
  end

  def accounting_date
    AccountingDate.find_by_id(accounting_date_id).accounting_date
  end

  def roll!(station_id, user_id)
    raise 'rolled_error' if self.roll_shift_at != nil

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

  def roll_by_system
    raise 'rolled_error' if self.roll_shift_at != nil

    self.roll_shift_on_station_id = 1
    self.roll_shift_by_user_id = 1
    self.roll_shift_at = Time.now.utc.to_formatted_s(:db)
    self.updated_at = Time.now.utc.to_formatted_s(:db)

    new_shift = Shift.new
    new_shift_name = self.class.next_shift_name_by_name(name)
    new_shift.shift_type_id = ShiftType.get_id_by_name(new_shift_name)
    new_shift.accounting_date_id = AccountingDate.next_shift_accounting_date_id(name)
    new_shift.created_at = Time.now.utc.to_formatted_s(:db)
    new_shift.updated_at = Time.now.utc.to_formatted_s(:db)

    Shift.transaction do
      self.save
      new_shift.save
    end
  end

  class << self
    def current
      shift = Shift.find_by_roll_shift_at_and_property_id(nil, PROPERTY_ID)
      raise 'Current shift not found!' unless shift
      shift
    end

    def next_shift_name_by_name( shift_name )
      shift_names = PropertiesShiftType.shift_types(PROPERTY_ID)
      return shift_names[0]if shift_names.index(shift_name).nil?
      shift_names[(shift_names.index(shift_name) + 1) % shift_names.length] 
    end
  end
end
