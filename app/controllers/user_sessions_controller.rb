class UserSessionsController < Devise::SessionsController
  layout "login"

  def get_terminal_id
    cookies[:terminal_id]
  end

  def set_location_info
    session[:location_info] = terminal_requester.retrieve_location_info(get_terminal_id) if get_terminal_id
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
