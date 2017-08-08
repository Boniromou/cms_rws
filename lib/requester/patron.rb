require File.expand_path(File.dirname(__FILE__) + "/base")

class Requester::Patron < Requester::Base
  
  def get_player_info(id_type, id_value)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('get', "#{@path}/#{__callee__}", :body => {:id_type => id_type, :id_value => id_value, :licensee_id => @licensee_id})
      self.send "parse_#{__callee__}_response", response
    end
  end
  
  def get_player_infos(member_ids)
    response = remote_rws_call('get', "#{@path}/#{__callee__}", :body => {:member_ids => member_ids, :licensee_id => @licensee_id})
    self.send "parse_#{__callee__}_response", response
  end

  def validate_pin(member_id, pin)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('get', "#{@path}/#{__callee__}", :body => {:member_id => member_id, :pin => pin, :licensee_id => @licensee_id})
      self.send "parse_#{__callee__}_response", response
    end
  end
     
  def reset_pin(member_id, pin, audit_log)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('post', "#{@path}/#{__callee__}", :body => {:member_id => member_id, :pin => pin, :audit_log => audit_log, :licensee_id => @licensee_id})
      self.send "parse_#{__callee__}_response", response
    end
  end

  def get_pin_audit_logs(start_time, end_time)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('get', "#{@path}/#{__callee__}", :body => {:start_time => start_time, :end_time => end_time, :licensee_id => @licensee_id})
      self.send "parse_#{__callee__}_response", response
    end
  end

  protected

  def parse_get_player_info_response(result)
    #return {:member_id => 123, :card_id => 102130320923, :blacklist => true, :pin_status => 'null'}
    result_hash = remote_response_checking(result, :error_code)
    response = Requester::PlayerInfoResponse.new(result_hash)
    raise Request::InvalidCardId.new unless response.success?
    raise Remote::PlayerNotFound, response.exception_msg unless response.success?
    return response
  end

  def parse_get_player_infos_response(result)
    result_hash = remote_response_checking(result, :error_code)
    response = Requester::PlayerInfosResponse.new(result_hash)
    raise Remote::PlayerNotFound, response.exception_msg unless response.success?
    raise Remote::PlayerNotFound, response.exception_msg unless response.players
    return response
  end

  def parse_validate_pin_response(result)
    result_hash = remote_response_checking(result, :error_code)
    response = Requester::ValidatePinResponse.new(result_hash)
    raise Remote::PinError, response.exception_msg if response.invalid_pin?
    raise Remote::PinError, response.exception_msg unless response.success?
    return response
  end

  def parse_reset_pin_response(result)
    result_hash = remote_response_checking(result, :error_code)
    response = Requester::PlayerInfoResponse.new(result_hash)
    raise Remote::PlayerNotFound, response.exception_msg unless response.success?
    return response
  end

  def parse_get_pin_audit_logs_response(result)
    result_hash = remote_response_checking(result, :error_code)
    response = Requester::PinAuditLogResponse.new(result_hash)
    raise Remote::InvalidTimeRange, response.exception_msg if response.invalid_time_range?
    audit_log_array = result_hash[:audit_logs]
    raise Remote::NoPinAuditLog, response.exception_msg unless response.audit_logs
    return response
  end
end
