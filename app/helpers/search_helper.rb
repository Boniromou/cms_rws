module SearchHelper
  include FormattedTimeHelper
  
  def get_time_range_by_accounting_date(start_date, end_date, search_range)
    shifts = get_start_and_end_shifts(start_date, end_date, search_range)
    start_time = shifts[0].created_at
    end_time = shifts[1].roll_shift_at || Time.now.utc

    start_time = start_time.strftime("%Y-%m-%d %H:%M:%S")
    end_time = end_time.strftime("%Y-%m-%d %H:%M:%S")
    [start_time, end_time]
  end

  def get_shifts(start_date, end_date, id_number, operation, search_range)
  	raise SearchPlayerTransaction::NoIdNumberError, "no_id" if id_number.blank? && operation == 'cash'
    get_start_and_end_shifts(start_date, end_date, search_range)
  end

  def get_start_and_end_shifts(start_date, end_date, search_range)
    start_ac_date = parse_search_date(start_date)
    end_ac_date = parse_search_date(end_date)

    raise Search::DateTimeError, "range_error" if to_number(end_ac_date) < to_number(start_ac_date)

    date_gap = (to_number(end_ac_date) - to_number(start_ac_date)) / (24 * 3600)
    raise Search::OverRangeError, "limit_remark" if date_gap > search_range

    first_ac_date = Shift.where(:property_id => current_property_id).order(:created_at).first.accounting_date
    last_ac_date = Shift.where(:property_id => current_property_id).order(:created_at).last.accounting_date

    raise Search::NoResultException, "accounting date not found" if to_number(end_ac_date) < to_number(first_ac_date) || to_number(last_ac_date) < to_number(start_ac_date)

    start_ac_date = AccountingDate.find_by_accounting_date(start_ac_date)
    end_ac_date = AccountingDate.find_by_accounting_date(end_ac_date)

    start_ac_date = AccountingDate.find_by_accounting_date(first_ac_date) if start_ac_date.nil?
    end_ac_date = AccountingDate.find_by_accounting_date(last_ac_date) if end_ac_date.nil?
  
    start_shift = Shift.where(:accounting_date_id => start_ac_date.id, :property_id => current_property_id).order(:created_at).first
    end_shift = Shift.where(:accounting_date_id => end_ac_date.id, :property_id => current_property_id).order(:created_at).last

    [start_shift, end_shift]
  end
end
