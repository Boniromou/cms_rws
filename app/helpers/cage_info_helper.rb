module CageInfoHelper
  def current_cage_location_str
    current_station.capitalize + "!!!"
  end

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

  protected

  def polling_interval
    #milliseconds
    60 * 1000 + rand(1..500)
  end

  def current_station
    "window#1"
  end
end
