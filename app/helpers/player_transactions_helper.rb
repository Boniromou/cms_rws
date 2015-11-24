module PlayerTransactionsHelper
  include FormattedTimeHelper
  def today_start_time
    Time.parse(Time.now.strftime("%d"))
  end

  def today_end_time
    today_start_time + 24*60*60 -1
  end

  def is_close_after_print
    true
  end

  def get_start_and_end_shifts(start_time, end_time, id_number, operation)
  	raise SearchPlayerTransaction::NoIdNumberError, "no_id" if id_number.blank? && operation == 'cash'
    raise Search::DateTimeError, "range_error" if to_number(@end_time) < to_number(@start_time)

    date_gap = (to_number(@end_time) - to_number(@start_time)) / 86400
    
    raise Search::OverRangeError, "limit_remark" if date_gap > TRANS_HISTORY_SEARCH_RANGE
    start_ac_date = AccountingDate.find_by_accounting_date(to_string(@start_time))
    end_ac_date = AccountingDate.find_by_accounting_date(to_string(@end_time))
    end_ac_date = AccountingDate.order(:created_at).last if end_ac_date.nil?

    raise Search::NoResultException, "accounting date not found" if start_ac_date.nil? || end_ac_date.nil? 
  
    start_shift = Shift.where(:accounting_date_id => start_ac_date.id).order(:created_at).first
    end_shift = Shift.where(:accounting_date_id => end_ac_date.id).order(:created_at).last
  
  	[start_shift, end_shift]
  end
end
