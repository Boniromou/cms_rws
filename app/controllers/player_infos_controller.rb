class PlayerInfosController < ApplicationController
  skip_before_filter :check_session_expiration, :authenticate_user!, :update_user_location
  include Hood::RWSHandler

  config_handler RequestHandler.instance, true
  config_handler_backtrace_cleaner Rails.backtrace_cleaner

  def retrieve_player_info
    handle_request(:retrieve_player_info)
  end

  def get_player_currency
    handle_request(:get_player_currency)
  end

  def is_test_mode_player
    handle_request(:is_test_mode_player)
  end
end
