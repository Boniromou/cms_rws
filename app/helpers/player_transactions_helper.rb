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
end
