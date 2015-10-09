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
      player = Player.find_by_member_id(login_name)
      raise Request::InvalidSessionToken.new unless player
      token = player.tokens.find_by_session_token(session_token)
      raise Request::InvalidSessionToken.new unless token
      raise Request::InvalidSessionToken.new unless token.belong_to?(login_name) && token.alive? && !token.player.account_locked?
      token
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
      token = self.validate(login_name, session_token)
      token.keep_alive
      token
    end

    def discard(login_name, session_token)
      token = self.validate(login_name, session_token)
      token.discard
      token
    end
	end
end
