class Shift < ActiveRecord::Base
  attr_accessible :shift_type_id, :user_id,  :accounting_date, :roll_shift_at, :station
end
