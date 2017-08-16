class InternalRequestsController < ApplicationController
  skip_before_filter :check_session_expiration, :authenticate_user!, :update_user_location
  include Hood::RWSHandler

  config_handler RequestHandler.instance, false
  config_handler_backtrace_cleaner Rails.backtrace_cleaner

  def validate
    handle_request(:validate_token)
  end

  def lock_player
    handle_request(:lock_player)
  end

  def internal_lock_player
    handle_request(:internal_lock_player, nil, false)
  end

  def internal_unlock_player
    handle_request(:internal_unlock_player, nil, false)
  end
end
