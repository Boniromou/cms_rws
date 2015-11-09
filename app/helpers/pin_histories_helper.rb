module PinHistoriesHelper
  include FormattedTimeHelper
  PIN_HISTORY_SEARCH_RANGE = 30
  
  def get_time_range_by_accounting_date(start_date, end_date)
  	@start_ac_date = parse_date(start_date, current_accounting_date.accounting_date)
    @end_ac_date = parse_date(end_date, current_accounting_date.accounting_date)
    start_ac_date_id = AccountingDate.get_by_date(@start_ac_date).id
    end_ac_date_id = AccountingDate.get_by_date(@end_ac_date).id
    start_time = Shift.where(:accounting_date_id => start_ac_date_id).order(:created_at).first.created_at
    end_time = Shift.where(:accounting_date_id => end_ac_date_id).order(:created_at).last.roll_shift_at
    start_time = Time.now.utc unless start_time
    end_time = Time.now.utc unless end_time

    raise Search::DateTimeError, "range_error" if to_number(end_time) < to_number(start_time)
    date_gap = (to_number(end_time) - to_number(start_time)) / 86400
    raise Search::OverRangeError, "limit_remark" if date_gap > PIN_HISTORY_SEARCH_RANGE

    [start_time, end_time]
  end
end