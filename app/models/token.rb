class Token < ActiveRecord::Base
    validates_uniqueness_of :session_token
    attr_accessible :session_token, :player_id, :expired_at
    belongs_to :player
	class << self
		def validate(login_name, session_token)
      token = Token.find_by_session_token(session_token)
      if token
        return {}, token if token.player.member_id == login_name && Time.now < token.expired_at
      end
      return {:error_code => 'InvalidSessionToken', :error_msg => 'Session token is invalid.'}, nil
    end

    def create(login_name, session_token)
    	token = new
    	token.player_id = Player.find_by_member_id(login_name)
		  token.session_token = session_token
		  token.expired_at = Time.now.utc + 30 * 60 
		  token.save
    end

    def keep_alive(login_name, session_token)
      response, token = self.validate(login_name, session_token)
      return response unless token
      token.expired_at = Time.now.utc + 30 * 60 
      token.save
      {}
    end

    def discard(login_name, session_token)
      response, token = self.validate(login_name, session_token)
      return response unless token
      token.expired_at = Time.now.utc - 100
      token.save
      {}
    end
	end
end