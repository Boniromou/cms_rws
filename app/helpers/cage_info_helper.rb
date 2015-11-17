module CageInfoHelper
  def update_accounting_date_interval
    polling_interval
  end

  def update_shift_interval
    polling_interval
  end

  def default_shift_widget_message
    "Waiting for shift"
  end

  def default_accounting_date_widget_message
    "Waiting for accounting date"
  end

  def default_location_widget_message
    "N/A"
  end

  protected

  def polling_interval
    #milliseconds
    # 60 * 1000 + rand(1..500)
    POLLING_TIME
  end
end
