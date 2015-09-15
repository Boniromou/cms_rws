class Token < ActiveRecord::Base
    validates_uniqueness_of :terminal_id
    attr_accessible :session_token, :player_id, :terminal_id, :expired_at, :property_id
    belongs_to :player
	class << self
		def validate(login_name, session_token)
      		token = Token.find_by_session_token(session_token)
      		if token
            player = Player.find_by_member_id('123456')
            if player
        		  return token if player.member_id == login_name && token.property_id == 20000 && Time.now < token.expired_at
      		  end
          end
      		{:error_code => 'InvalidSessionToken', :error_msg => 'Session token is invalid'}
    	end

    	def create(login_name, session_token, property_id, terminal_id)
    		token = new
    		token.terminal_id = terminal_id
    		token.player_id = Player.find_by_member_id(login_name)
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
    	self.destroy
    end
end