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
    machine_type = @inbound[:machine_type]
    card_id = @inbound[:card_id]
    machine_token = @inbound[:machine_token]
    pin = @inbound[:pin]
    property_id = @inbound[:property_id]
    PlayerInfo.retrieve_info(card_id, machine_type, machine_token, pin, property_id)
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
    ApiHelper.get_currency(login_name, property_id)
  end

  def process_lock_player_event
    property_id = @inbound[:property_id]
    login_name = @inbound[:login_name]
    ApiHelper.lock_player(login_name, property_id)
  end

  def process_validate_machine_token_event
    machine_type = @inbound[:machine_type]
    property_id = @inbound[:property_id]
    machine_token = @inbound[:machine_token]
    Machine.validate(machine_type, machine_token, property_id)
  end
end
