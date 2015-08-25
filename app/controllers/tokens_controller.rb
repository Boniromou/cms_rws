class TokensController < ApplicationController
  skip_before_filter :check_session_expiration, :authenticate_user!,:pass_terminal_id
  include Hood::RWSHandler

  config_handler RequestHandler.instance,false
  config_handler_backtrace_cleaner Rails.backtrace_cleaner

  def validate
    handle_request(:validate_token)
  end

  def retrieve_player_info
    handle_request(:retrieve_player_info)
  end

end
