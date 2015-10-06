class Token < ActiveRecord::Base
    validates_uniqueness_of :session_token
    attr_accessible :session_token, :player_id, :expired_at
    belongs_to :player
	class << self
		def validate(login_name, session_token)
      		token = Token.find_by_session_token(session_token)
      		if token
            player = Player.find(token.player_id)
            if player
        		  return token if player.member_id == login_name && Time.now < token.expired_at
      		  end
          end
      		{:error_code => 'InvalidSessionToken', :error_msg => 'Session token is invalid.'}
    	end

    	def create(login_name, session_token)
    		token = new
    		token.player_id = Player.find_by_member_id(login_name)
		    token.session_token = session_token
		    token.expired_at = Time.now.utc + 1800
		    token.save
    	end
	end

	def keep_alive
    	self.expired_at += 1800
    	self.save
    end

  def discard
    self.expired_at = (Time.now.utc - 100)
    self.save
  end
end