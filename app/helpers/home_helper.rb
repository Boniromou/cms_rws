module HomeHelper
  def get_machine_token
    cookies[:machine_token]
  end

  def set_location_info
    session[:location_info] = nil
    session[:casino_info] = nil
    session[:machine_token] = nil

    if get_machine_token
      response = station_requester.validate_machine_token(MACHINE_TYPE, get_machine_token, nil, current_casino_id)
      if response.success?
        if response.zone_name != nil && response.location_name != nil
          session[:location_info] = response.zone_name + '/' + response.location_name
          session[:casino_info] = Casino.find_by_id(response.casino_id).name
          session[:machine_token] = get_machine_token
        end
      end
    end
  end
end
