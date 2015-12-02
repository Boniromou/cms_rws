class TokensController < ApplicationController
  skip_before_filter :check_session_expiration, :authenticate_user!, :update_user_location
  include Hood::RWSHandler

  config_handler RequestHandler.instance, true
  config_handler_backtrace_cleaner Rails.backtrace_cleaner

  def validate
    handle_request(:validate_token)
  end

  def keep_alive
    handle_request(:keep_alive)
  end

  def discard
    handle_request(:discard_token)
  end
end
