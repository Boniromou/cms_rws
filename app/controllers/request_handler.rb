require 'singleton'
class RequestHandler
  include Singleton

  def update(inbound)
    @inbound = inbound
    begin
      event_name = inbound[:_event_name].to_sym
      @outbound = self.__send__("process_#{event_name}_event") || {}
    rescue Request::RequestError => e
      @outbound = e.to_hash
    rescue Exception => e
      puts e.backtrace
      puts e.message
      {:status => 500, :error_code => 'internal error', :error_msg => 'e.message'}
    end
    if @outbound[:error_code].nil?
      @outbound.merge!({:status=>200, :error_code=>'OK', :error_msg=>'Request is carried out successfully.'})
    end
    @outbound
  end

  def process_validate_token_event
    Token.validate(@inbound[:login_name], @inbound[:session_token], @inbound[:property_id])
    {}
  end
  
  def process_retrieve_player_info_event
    card_id = @inbound[:card_id]
    terminal_id = @inbound[:terminal_id]
    pin = @inbound[:pin]
    property_id = @inbound[:property_id]
    PlayerInfo.retrieve_info(card_id, terminal_id, pin, property_id)
  end

  def process_keep_alive_event
    Token.keep_alive(@inbound[:login_name], @inbound[:session_token], @inbound[:property_id])
    {}
  end

  def process_discard_token_event
    Token.discard(@inbound[:login_name], @inbound[:session_token], @inbound[:property_id])
    {}
  end

  def process_keep_eternal_alive_event
    property_id = @inbound[:property_id]
    member_id = @inbound[:login_name]
    session_token = 'null'
    player = Player.where(:property_id => property_id, :member_id => member_id).first
    return {:status => 400, :error_code=>'PlayerNotFound', :error_msg=>'Player is not exist.'} unless player
    token = Token.where(:player_id => player.id, :session_token => session_token).first
    token = Token.new unless token
    token.player_id = player.id
    token.expired_at = '3012-12-20 00:00:00'
    token.session_token = 'null'
    token.save({:validate => false})
    {}
  end

  def process_get_player_currency_event
    property_id = @inbound[:property_id]
    login_name = @inbound[:login_name]
    PlayerInfo.get_currency(login_name, property_id)
  end
  #mock
  def process_validate_terminal_event
    return {:machine_name => 'abc1234'} if @inbound[:terminal_id] == 'eb693ec8252cd630102fd0d0fb7c3485'
    {:error_code => 'InvalidTerminalID', :error_msg => 'Validate terminal id failed.'}
  end
end
