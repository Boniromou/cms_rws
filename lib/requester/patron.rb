require File.expand_path(File.dirname(__FILE__) + "/standard")

class Requester::Patron < Requester::Standard
  
  def get_player_info(id_type, id_value)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('get', "#{@path}/#{__callee__}", :body => {:id_type => id_type, :id_value => id_value})
      self.send "parse_#{__callee__}_response", response
    end
  end
  
  def get_player_infos(member_ids)
    response = remote_rws_call('get', "#{@path}/#{__callee__}", :body => {:member_ids => member_ids})
    self.send "parse_#{__callee__}_response", response
  end

  def validate_pin(member_id, pin)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('get', "#{@path}/#{__callee__}", :body => {:member_id => member_id, :pin => pin})
      self.send "parse_#{__callee__}_response", response
    end
  end
     
  def reset_pin(member_id, pin, audit_log)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('post', "#{@path}/#{__callee__}", :body => {:member_id => member_id, :pin => pin, :audit_log => audit_log})
      self.send "parse_#{__callee__}_response", response
    end
  end

  def get_pin_audit_logs(start_time, end_time)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('post', "#{@path}/#{__callee__}", :body => {:start_time => start_time, :end_time => end_time})
      self.send "parse_#{__callee__}_response", response
    end
  end

  protected

  def parse_get_player_info_response(result)
    #return {:member_id => 123, :card_id => 102130320923, :blacklist => true, :pin_status => 'null'}
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    raise Remote::PlayerNotFound, "error_code #{error_code}: #{message}" unless ['OK'].include?(error_code)
    player_info = result_hash[:player]
    return player_info
  end

  def parse_get_player_infos_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    raise Remote::PlayerNotFound, "error_code #{error_code}: #{message}" unless ['OK'].include?(error_code)
    player_info_array = result_hash[:players]
    raise Remote::PlayerNotFound, "error_code #{error_code}: #{message}" if player_info_array.nil?
    return player_info_array
  end

  def parse_validate_pin_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    error_msg = result_hash[:error_msg].to_s
    raise Remote::PinError, "error_code #{error_code}: #{error_msg}" if ['InvalidPin'].include?(error_code)
    player_info = result_hash[:player]
    raise Remote::PlayerNotFound, "error_code #{error_code}: #{error_msg}" if player_info.nil?
    raise Remote::PinError, "error_code #{error_code}: #{error_msg}" unless ['OK'].include?(error_code)
    return player_info
  end

  def parse_reset_pin_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    raise Remote::PlayerNotFound, "error_code #{error_code}: #{message}" unless ['OK'].include?(error_code)
    player_info = result_hash[:player]
    raise Remote::PlayerNotFound, "error_code #{error_code}: #{message}" if player_info.nil?
    return player_info
  end

  def parse_get_pin_audit_logs_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    raise Remote::InvalidTimeRange, "error_code #{error_code}: #{message}" if ['InvalidTimeRange'].include?(error_code)
    audit_log_array = result_hash[:audit_logs]
    raise Remote::NoPinAuditLog, "error_code #{error_code}: #{message}" if audit_log_array.nil?
    return audit_log_array
  end
end
