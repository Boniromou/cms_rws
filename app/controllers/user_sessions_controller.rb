class UserSessionsController < Devise::SessionsController
  layout "login"

  def get_machine_token
    cookies[:machine_token]
  end

  def set_location_info
    if get_machine_token
      session[:location_info] = station_requester.validate_machine_token(get_machine_token, PROPERTY_ID)[:location_name]
    else
      session[:location_info] = nil
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
