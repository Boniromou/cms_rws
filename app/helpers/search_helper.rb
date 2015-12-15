module SearchHelper
  include FormattedTimeHelper
  
  def get_time_range_by_accounting_date(start_date, end_date, search_range)
    @start_ac_date = parse_date(start_date, current_accounting_date.accounting_date)
    @end_ac_date = parse_date(end_date, current_accounting_date.accounting_date)

    raise Search::DateTimeError, "range_error" if @end_ac_date.to_time.to_i < @start_ac_date.to_time.to_i
    date_gap = (@end_ac_date.to_time.to_i - @start_ac_date.to_time.to_i) / 86400
    raise Search::OverRangeError, "limit_remark" if date_gap > search_range

    start_ac_date_id = AccountingDate.get_by_date(@start_ac_date).id
    end_ac_date_id = AccountingDate.get_by_date(@end_ac_date).id
    start_time = Shift.where(:accounting_date_id => start_ac_date_id).order(:created_at).first.created_at
    end_time = Shift.where(:accounting_date_id => end_ac_date_id).order(:created_at).last.roll_shift_at
    start_time = Time.now.utc unless start_time
    end_time = Time.now.utc unless end_time

    start_time = start_time.strftime("%Y-%m-%d %H:%M:%S")
    end_time = end_time.strftime("%Y-%m-%d %H:%M:%S")
    [start_time, end_time]
  end

  def get_start_and_end_shifts(start_time, end_time, id_number, operation, search_range)
  	raise SearchPlayerTransaction::NoIdNumberError, "no_id" if id_number.blank? && operation == 'cash'
    raise Search::DateTimeError, "range_error" if to_number(@end_time) < to_number(@start_time)

    date_gap = (to_number(@end_time) - to_number(@start_time)) / 86400
    
    raise Search::OverRangeError, "limit_remark" if date_gap > search_range
    start_ac_date = AccountingDate.find_by_accounting_date(to_string(@start_time)) || AccountingDate.first
    end_ac_date = AccountingDate.find_by_accounting_date(to_string(@end_time))
    end_ac_date = AccountingDate.order(:created_at).last if end_ac_date.nil?

    raise Search::NoResultException, "accounting date not found" if start_ac_date.nil? || end_ac_date.nil? 
  
    start_shift = Shift.where(:accounting_date_id => start_ac_date.id).order(:created_at).first
    end_shift = Shift.where(:accounting_date_id => end_ac_date.id).order(:created_at).last
  
  	[start_shift, end_shift]
  end
end
