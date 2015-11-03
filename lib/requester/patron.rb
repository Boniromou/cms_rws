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

  protected

  def parse_get_player_info_response(result)
    #return {:member_id => 123, :card_id => 102130320923, :blacklist => true, :pin_status => 'null'}
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    raise Remote::PlayerNotFound, "error_code #{error_code}: #{message}" unless ['OK'].include?(error_code)
    return result_hash
  end

  def parse_get_player_infos_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    raise Remote::PlayerNotFound, "error_code #{error_code}: #{message}" unless ['OK'].include?(error_code)
    player_info_array = result_hash[:player_infos]
    raise Remote::PlayerNotFound, "error_code #{error_code}: #{message}" if player_info_array.nil?
    return player_info_array
  end
end
