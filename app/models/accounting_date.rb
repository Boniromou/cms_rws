class AccountingDate < ActiveRecord::Base
  attr_accessible :accounting_date
  has_many :shifts
  include FrontMoneyHelper

  class << self
    def current(casino_id)
      self.find_by_id(Shift.current(casino_id).accounting_date_id)
    end

    def next_shift_accounting_date_id(shift_name, casino_id)
      shift_names = CasinosShiftType.shift_types(casino_id)
      last_shift_name = shift_names[-1]
      if shift_name == last_shift_name
        current_ac_date = current(casino_id).accounting_date
        new_ac_date = AccountingDate.where(:accounting_date => current_ac_date + 1).first_or_initialize
        new_ac_date.created_at ||= Time.now.utc.to_formatted_s(:db)
        new_ac_date.updated_at ||= Time.now.utc.to_formatted_s(:db)
        new_ac_date.save
        new_ac_date.id
      else
        current(casino_id).id
      end
    end

    def next_shift_accounting_date(shift_name, current_ac_date, casino_id)
      shift_names = CasinosShiftType.shift_types(casino_id)
      last_shift_name = shift_names[-1]
      if shift_name == last_shift_name
        return current_ac_date + 1
      else
        return current_ac_date
      end
    end

    def get_by_date( date )
      accounting_date = self.find_by_accounting_date(date)
      raise FrontMoneyHelper::NoResultException.new "accounting date not exist" if accounting_date.nil?
      accounting_date
    end
  end

end
