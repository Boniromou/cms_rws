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
  
  def format_time_slip(time)
    begin
      unless time.blank?
        time.getlocal.strftime("%d-%b-%Y %I:%M:%S %p")
      end
    rescue Exception
      Time.parse(time).getlocal.strftime("%d-%b-%Y %I:%M:%S %p")
    end
  end

  def format_time_slip_date(time)
    begin
      unless time.blank?
        time.getlocal.strftime("%d-%b-%Y")
      end
    rescue Exception
      Time.parse(time).getlocal.strftime("%d-%b-%Y")
    end
  end

  def format_time_slip_time(time)
    begin
      unless time.blank?
        time.getlocal.strftime("%I:%M:%S %p")
      end
    rescue Exception
      Time.parse(time).getlocal.strftime("%I:%M:%S %p")
    end
  end
  
  def format_date(date)
    date.strftime("%Y-%m-%d")
  end
  
  def parse_date(date_str, default_date)
    begin
      Date.parse(date_str)
    rescue ArgumentError
      default_date
    end
  end

  def parse_search_date(date_str)
    begin
      Date.parse(date_str)
    rescue ArgumentError
      raise ArgumentError 
    end
  end

  def parse_datetime(datetime_str, default_time=Time.now)
    begin
      Time.strptime(datetime_str, "%Y-%m-%d %H:%M:%S").utc
    rescue ArgumentError
      raise ArgumentError 
    end
  end

  def parse_search_time(date_str, is_end_time=false)
    begin
      if is_end_time
        Time.strptime(date_str, "%Y-%m-%d")
        return Time.strptime(date_str + " 23:59:59", "%Y-%m-%d %H:%M:%S").utc
      else
        Time.strptime(date_str, "%Y-%m-%d").utc
        # return Time.strptime(date_str, "%Y-%m-%d").utc
      end
    rescue ArgumentError
      raise ArgumentError
    end
  end

  def to_number(date_str)
    date_str.to_time.to_i if date_str
  end
end
