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

  def update_station_interval
    polling_interval
  end

  def default_shift_widget_message
    "Waiting for shift"
  end

  def default_accounting_date_widget_message
    "Waiting for accounting date"
  end

  def default_station_widget_message
    "No location"
  end

  protected

  def polling_interval
    #milliseconds
    6 * 1000 + rand(1..500)
  end

  def current_station
    "Main Cage - Window#1"
  end
end
