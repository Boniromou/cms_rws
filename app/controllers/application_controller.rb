class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user!

  layout false

  include Pundit
  include CageInfoHelper

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

  def current_shift
    Shift.current
  end

  def current_accounting_date
    AccountingDate.current
  end

  def current_station_id
    #TODO
    1
  end

  def permission_granted?(model, operation = nil)
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
    end
    true
  end
end
