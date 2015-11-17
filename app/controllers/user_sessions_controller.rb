class UserSessionsController < Devise::SessionsController
  layout "login"

  def get_machine_token
    cookies[:machine_token]
  end

  def set_location_info
    if get_machine_token
      response = station_requester.validate_machine_token(MACHINE_TYPE, get_machine_token, PROPERTY_ID)
      if response.class != Hash
        Rails.logger.error "retrieve location name fail"
      return
      end
      session[:location_info] = response[:zone_name] + '/' + response[:location_name] if response[:error_code] == 'OK' && response[:zone_name] != nil && response[:location_name] != nil
      session[:machine_token] = get_machine_token if session[:location_info]
    end
  end  

  def new
    @login_url = %(#{root_url}login)
    set_location_info
  end

  def create
    super
    set_location_info
  end

  def destroy
    super
  end

  def after_sign_in_path_for(resource)
    if resource.is_a?(User)
      #Rails.logger.info "A SystemUser logged in. Session=#{session.inspect}"
      #Rails.logger.info request.session_options.inspect
      Rails.application.routes.recognize_path default_selected_function
    elsif
      root_path
    end
  end

  def default_selected_function
    # TODO: determine what path to redirect to based on role/permission
    "home"
  end

  def after_sign_out_path_for(resource)
    login_path
  end
end
