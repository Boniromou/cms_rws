class EternalTokensController < ApplicationController
  skip_before_filter :check_session_expiration, :authenticate_user!, :update_user_location
  include Hood::RWSHandler

  config_handler RequestHandler.instance,false
  config_handler_backtrace_cleaner Rails.backtrace_cleaner

  def keep_eternal_alive
    handle_request(:keep_eternal_alive)
  end
end
