class ApplicationController < ActionController::Base
  layout false
  protect_from_forgery
  before_filter :authenticate_user!
end
