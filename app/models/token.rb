class Token < ActiveRecord::Base
    validates_uniqueness_of :terminal_id
	class << self
		def validate(login_name, session_token)
      		token = Token.find_by_session_token(session_token)
      		if token
        		return token if token.login_name == login_name && token.property_id == 20000 && Time.now < token.expired_at
      		end
      		{:error_code => 'InvalidSessionToken', :error_msg => 'Session token is invalid'}
    	end

    	def create_or_update(login_name, session_token, property_id, terminal_id)
    		token = Token.find_by_terminal_id(terminal)
    		unless token
    			token = new
    			token.terminal_id = terminal_id
    		end
    		token.login_name = login_name
		    token.session_token = session_token
		    token.property_id = property_id
		    
		    token.expired_at = Time.now + 1800
		    token.save
    	end
	end

	def keep_alive
    	self.expired_at += 1800
    	self.save
    end

    def discard
    	self.expired_at = nil
    	self.login_name = nil
    	self.property_id = nil
    	self.session_token = nil
    	self.save
    end
end