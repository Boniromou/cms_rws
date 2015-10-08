class Token < ActiveRecord::Base
    validates_uniqueness_of :session_token
    attr_accessible :session_token, :player_id, :expired_at
    belongs_to :player
    EXPIRE_TIME = 30 * 60
  
  def alive?
    self.expired_at > Time.now
  end

  def belong_to?(login_name)
    self.player.member_id == login_name
  end

  def discard
    self.expired_at = Time.now.utc - 100
    self.save
  end

  def keep_alive
    self.expired_at = Time.now.utc + EXPIRE_TIME
    self.save
  end

	class << self
		def validate(login_name, session_token)
      token = Token.find_by_session_token(session_token)
      return {:error_code => 'InvalidSessionToken', :error_msg => 'Session token is invalid.'}, nil unless token
      return {}, token if token.belong_to?(login_name) && token.alive?
    end

   	def generate(player_id)
    	token = new
    	token.player_id = player_id
		  token.session_token = SecureRandom.uuid
		  token.expired_at = Time.now.utc + EXPIRE_TIME
		  token.save
      token
    end

    def keep_alive(login_name, session_token)
      response, token = self.validate(login_name, session_token)
      return response if response[:error_code] == 'InvalidSessionToken'
      token.keep_alive
      {}
    end

    def discard(login_name, session_token)
      response, token = self.validate(login_name, session_token)
      return response if response[:error_code] == 'InvalidSessionToken'
      token.discard
      {}
    end
	end
end
