class MachinesController < ApplicationController
  skip_before_filter :check_session_expiration, :authenticate_user!, :update_user_location
  include Hood::RWSHandler

  config_handler RequestHandler.instance, true
  config_handler_backtrace_cleaner Rails.backtrace_cleaner

  def validate
  	handle_request(:validate_machine_token)
  end

  def current_location
    respond_to do |format|
      format.html { render :text => get_location_info , :layout => false }
    end
  end
end
