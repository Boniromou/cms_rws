class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :check_session_expiration, :authenticate_user!, :pass_terminal_id

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

  def wallet_requester
    Requester::Wallet.new(PROPERTY_ID, 'test_key', WALLET_URL + WALLET_PATH)
  end

  def patron_requester
    Requester::Patron.new(PROPERTY_ID, 'test_key', PATRON_URL)
  end
  
  def station_requester
    Requester::Station.new(STATION_URL)
  end

  protected

  def check_session_expiration
    if session[:accessed_at] && Time.now.utc - session[:accessed_at] > SESSION_EXPIRATION_TIME
      reset_session
    else
      session[:accessed_at] = Time.now.utc
    end
  end

  def pass_terminal_id
    current_user.set_have_enable_station(true) if is_have_enable_station && current_user
  end

  def is_have_enable_station
    session[:machine_token] == cookies[:machine_token] && cookies[:machine_token] != nil
  end

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
    @current_station = Station.find_by_terminal_id(request.headers['TerminalID'])
    return @current_station.id if @current_station
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
      respond_to do |format|
        format.html { render "home/index", formats: [:html] }
        format.js { render "home/unauthorized", formats: [:js] }
      end
      return false
    end
    true
  end

  def handle_fatal_error(e)
    @from = params[:from]
    Rails.logger.error "#{e.message}"
    Rails.logger.error "#{e.backtrace.inspect}"
    puts e.backtrace
    puts e.message
    respond_to do |format|
      format.html { render partial: "shared/error500", formats: [:html], layout: "error_page", :status => :internal_server_error }
      format.js { render partial: "shared/error500", formats: [:js], :status => :internal_server_error }
    end
    return
  end

  def get_location_name
    return session[:location_name] if session[:location_name]
    'No location'
  end
end
