class ApplicationController < ActionController::Base
  layout false
  protect_from_forgery
  before_filter :authenticate_user!

  def client_ip
    if Rails.env.development?
      request.remote_ip
    else
      request.env["HTTP_X_FORWARDED_FOR"]
     end
   end
  
  protected
  def sid
    request.session_options[:id]
  end

end
