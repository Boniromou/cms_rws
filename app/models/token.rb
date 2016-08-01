class Token < ActiveRecord::Base
    validates_uniqueness_of :session_token
    attr_accessible :session_token, :player_id, :expired_at
    attr_accessor :casino_id
    belongs_to :player
  
  def alive?
    self.expired_at > Time.now
  end

  def belong_to?(login_name)
    self.player.member_id == login_name
  end

  def discard
    self.expired_at = (Time.now.utc - 100).to_formatted_s(:db)
    self.save
  end

  def keep_alive
    self.expired_at = (Time.now.utc + self.token_life_time).to_formatted_s(:db)
    self.save
  end
  
  def token_life_time
    ConfigHelper.new(self.casino_id).token_life_time
  end

	class << self
    def validate(login_name, session_token, licensee_id)
      player = Player.find_by_member_id_and_licensee_id(login_name, licensee_id)
      raise Request::InvalidLoginName unless player
      token = player.tokens.find_by_session_token(session_token)
      raise Request::InvalidSessionToken unless token
      raise Request::InvalidSessionToken unless token.belong_to?(login_name) && token.alive? && !token.player.account_locked?
      token
    end

    def generate(player_id, casino_id)
      token = new
      token.player_id = player_id
      token.session_token = SecureRandom.uuid
      token.casino_id = casino_id
      token.expired_at = (Time.now.utc + token.token_life_time).to_formatted_s(:db)
      token.save
      token
    end

    def keep_alive(login_name, session_token, casino_id)
      token = self.validate(login_name, session_token, casino_id)
      token.casino_id = casino_id
      token.keep_alive
      token
    end

    def discard(login_name, session_token, licensee_id)
      token = self.validate(login_name, session_token, licensee_id)
      token.discard
      token
    end
    
    def clean_expired_tokens
      tokens = Token.where('expired_at < ?', Time.now.utc.to_formatted_s(:db))
      puts "#{tokens.length} tokens expired"
      tokens.delete_all        
    end
	end
end
