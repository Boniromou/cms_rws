class TerminalsController < ApplicationController
  skip_before_filter :check_session_expiration, :authenticate_user!,:pass_terminal_id
  include Hood::RWSHandler

  config_handler RequestHandler.instance,false
  config_handler_backtrace_cleaner Rails.backtrace_cleaner

  def validate
  	# new_params = {:login_name => params[:login_name], :session_token => params[:session_token] }
   #  redirect_to "http://marcusao01.rnd.laxino.com:3000/validate_token?#{new_params.to_query}"
  	# mock
  	handle_request(:validate_terminal)
  end
end