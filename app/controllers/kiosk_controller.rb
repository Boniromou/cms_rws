class KioskController < ApplicationController
  skip_before_filter :check_session_expiration, :authenticate_user!, :update_user_location
  include Hood::RWSHandler

  config_handler RequestHandler.instance, true
  config_handler_backtrace_cleaner Rails.backtrace_cleaner

  def kiosk_login
    handle_request(:kiosk_login)
  end

  def validate_deposit
    handle_request(:validate_deposit)
  end

  def deposit
    handle_request(:deposit)
  end

  def withdraw
    handle_request(:withdraw)
  end

  def internal_deposit
    handle_request(:internal_deposit, nil, false)
  end
end
