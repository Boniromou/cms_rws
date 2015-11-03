class TokensController < ApplicationController
  skip_before_filter :check_session_expiration, :authenticate_user!, :pass_terminal_id
  include Hood::RWSHandler

  config_handler RequestHandler.instance, true
  config_handler_backtrace_cleaner Rails.backtrace_cleaner

  def validate
    handle_request(:validate_token)
  end

  def retrieve_player_info
    handle_request(:retrieve_player_info)
  end

  def keep_alive
    handle_request(:keep_alive)
  end

  def discard
    handle_request(:discard_token)
  end

  def get_player_currency
    handle_request(:get_player_currency)
  end

  def validate_machine
    # new_params = {:login_name => params[:login_name], :session_token => params[:session_token] }
   #  redirect_to "http://marcusao01.rnd.laxino.com:3000/validate_token?#{new_params.to_query}"
    # mock
    handle_request(:validate_machine_token)
  end
end
