module PinHistoriesHelper
  include FormattedTimeHelper
  PIN_HISTORY_SEARCH_RANGE = 30
  
  def get_time_range_by_accounting_date(start_date, end_date)
  	@start_ac_date = parse_date(start_date, current_accounting_date.accounting_date)
    @end_ac_date = parse_date(end_date, current_accounting_date.accounting_date)

    raise Search::DateTimeError, "range_error" if @end_ac_date.to_time.to_i < @start_ac_date.to_time.to_i
    date_gap = (@end_ac_date.to_time.to_i - @start_ac_date.to_time.to_i) / 86400
    raise Search::OverRangeError, "limit_remark" if date_gap > PIN_HISTORY_SEARCH_RANGE

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
end