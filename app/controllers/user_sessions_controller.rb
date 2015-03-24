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

  #def failure
  #  return render :json => {:success => false, :errors => ["Login failed."]}
  #end
end
