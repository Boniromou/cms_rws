module ControllerHelpers
    def login_root
      before(:each) do
	@request.env["devise.mapping"] = Devise.mappings[:system_user]
        root = SystemUser.find_by_username("mo\portal.admin")
        sign_in root # Using factory girl as an example
        @current_user = root
      end
    end
  end

