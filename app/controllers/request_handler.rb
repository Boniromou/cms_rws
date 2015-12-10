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

  def get_requester_helper(property_id)
    requester_config_file = "#{Rails.root}/config/requester_config.yml"
    requester_facotry = Requester::RequesterFactory.new(requester_config_file, Rails.env, property_id, Property.get_property_keys[property_id])
    RequesterHelper.new(requester_facotry)
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
    get_requester_helper(property_id).retrieve_info(card_id, machine_type, machine_token, pin, property_id)
  end

  def process_keep_alive_event
    Token.keep_alive(@inbound[:login_name], @inbound[:session_token], @inbound[:property_id])
    {}
  end

  def process_discard_token_event
    Token.discard(@inbound[:login_name], @inbound[:session_token], @inbound[:property_id])
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
    get_requester_helper(property_id).validate_machine(machine_type, machine_token, property_id)
  end
end
