class ApplicationController < ActionController::Base
  layout false
  include Pundit
  protect_from_forgery
  before_filter :authenticate_user!

  def client_ip
    if Rails.env.development?
      request.remote_ip
    else
      request.env["HTTP_X_FORWARDED_FOR"]
     end
   end
  
  protected
  def sid
    request.session_options[:id]
  end

  def current_station
    "window#1"
  end

  def current_shift
    shift = Shift.new
  end

  def check_permission(model, operation = nil)
    begin
      if operation.nil?
        authorize model
      else
        authorize model, operation
      end
    rescue NotAuthorizedError => e
      flash[:alert] = "flash_message.not_authorize"
      redirect_to home_path
      return false
    rescue Exception
    end
    true
  end

end
