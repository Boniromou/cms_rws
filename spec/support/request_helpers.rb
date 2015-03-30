require 'rails_helper'
include Warden::Test::Helpers

module RequestHelpers
  def login_as_root
    user = SystemUser.find_by_username("mo\portal.admin")
    login(user)
    user
  end

  def login(user)
    login_as user, scope: :system_user
  end
end
