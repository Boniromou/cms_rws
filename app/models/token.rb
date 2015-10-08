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

   	def generate(player_id)
    	token = new
    	token.player_id = player_id
		  token.session_token = SecureRandom.uuid
		  token.expired_at = Time.now.utc + 1800
		  token.save
      token
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

  def discard
    self.expired_at = Time.now.utc - 100
    self.save
  end
end
