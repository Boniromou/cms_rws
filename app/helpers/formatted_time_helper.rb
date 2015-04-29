module FormattedTimeHelper
  def format_time(time)
    begin
      unless time.blank?
        time.getlocal.strftime("%Y-%m-%d %H:%M:%S")
      end
    rescue Exception
      Time.parse(time).getlocal.strftime("%Y-%m-%d %H:%M:%S")
    end
  end
  
  def parse_date(date_str)
    Date.parse(date_str)
  end

  def parse_datetime(datetime_str)
    Time.strptime(datetime_str, "%Y-%m-%d %H:%M:%S")
  end
end
