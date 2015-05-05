class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user!

  layout false

  include Pundit
  include CageInfoHelper

  rescue_from Exception, :with => :handle_fatal_error

  def client_ip
    if Rails.env.development?
      request.remote_ip
    else
      request.env["HTTP_X_FORWARDED_FOR"]
    end
  end

  def handle_route_not_found
    respond_to do |format|
      format.html { render partial: "shared/error404", formats: [:html], layout: "error_page", :status => :not_found }
      format.js { render partial: "shared/error404", formats: [:js], :status => :not_found }
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

  def handle_fatal_error(e)
    @from = params[:from]
    Rails.logger.error "#{e.message}"
    Rails.logger.error "#{e.backtrace.inspect}"
    respond_to do |format|
      format.html { render partial: "shared/error500", formats: [:html], layout: "error_page", :status => :internal_server_error }
      format.js { render partial: "shared/error500", formats: [:js], :status => :internal_server_error }
    end
    return
  end
end
