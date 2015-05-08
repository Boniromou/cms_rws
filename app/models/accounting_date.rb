class AccountingDate < ActiveRecord::Base
  attr_accessible :accounting_date
  include FrontMoneyHelper

  class << self
    NEXT_ACCOUNTING_DATE_ON_SHIFT_ROLLED = 'night'

    def current
      self.find_by_id(Shift.current.accounting_date_id)
    end

    def next_shift_accounting_date_id( shift_name )
      if shift_name == NEXT_ACCOUNTING_DATE_ON_SHIFT_ROLLED
        new_ac_date = new
        new_ac_date.accounting_date = current.accounting_date + 1
        new_ac_date.save
        new_ac_date.id
      else
        current.id
      end
    end

    def get_id_by_date( date )
      accounting_date = self.find_by_accounting_date(date)
      raise FrontMoneyHelper::NoResultException.new "accounting date not exist" if accounting_date.nil?
      accounting_date
    end
  end

end
