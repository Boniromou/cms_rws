class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user!

  layout false

  include Pundit

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
    shift = Shift.find_by_roll_shift_at(nil)
    raise 'Current shift not found!' unless shift
    shift
  end

  def current_accounting_date
    AccountingDate.find_by_id(current_shift.accounting_date_id)
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
