class UserSessionsController < Devise::SessionsController
  layout "login"  

  def new
    #super
  end

  def create
    super
  end

  def destroy
    super
  end
end
