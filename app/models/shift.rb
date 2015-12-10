class Shift < ActiveRecord::Base
  attr_accessible :shift_type_id, :roll_shift_by_user_id, :roll_shift_on_machine_token, :accounting_date_id, :roll_shift_at, :property_id
  belongs_to :shift_type

  def name
    ShiftType.get_name_by_id(shift_type_id)
  end

  def accounting_date
    AccountingDate.find_by_id(accounting_date_id).accounting_date
  end

  def roll!(machine_token, user_id)
    raise 'rolled_error' if self.roll_shift_at != nil

    self.machine_token = machine_token
    self.roll_shift_by_user_id = user_id
    self.roll_shift_at = Time.now.utc.to_formatted_s(:db)
    self.updated_at = Time.now.utc.to_formatted_s(:db)

    new_shift = Shift.new
    new_shift_name = self.class.next_shift_name_by_name(name, self.property_id)
    new_shift.shift_type_id = ShiftType.get_id_by_name(new_shift_name)
    new_shift.accounting_date_id = AccountingDate.next_shift_accounting_date_id(name, self.property_id)
    new_shift.property_id = self.property_id
    new_shift.created_at = Time.now.utc.to_formatted_s(:db)
    new_shift.updated_at = Time.now.utc.to_formatted_s(:db)

    Shift.transaction do
      self.save
      new_shift.save
    end
  end

  class << self
    def current(property_id)
      shift = Shift.find_by_roll_shift_at_and_property_id(nil, property_id)
      raise "Current shift not found!, property_id: #{property_id}" unless shift
      shift
    end

    def next_shift_name_by_name(shift_name, property_id)
      shift_names = PropertiesShiftType.shift_types(property_id)
      return shift_names[0]if shift_names.index(shift_name).nil?
      shift_names[(shift_names.index(shift_name) + 1) % shift_names.length] 
    end
  end
end
