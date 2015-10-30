require File.expand_path(File.dirname(__FILE__) + "/standard")

class Requester::Patron < Requester::Standard
  
  def get_player_info(id_type, id_value)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('get', "#{@path}/#{__callee__}", :body => {:id_type => id_type, :id_value => id_value})
      self.send "parse_#{__callee__}_response", response
    end
  end

  protected

  def parse_get_player_info_response(result)
    #return {:member_id => 123, :card_id => 102130320923, :blacklist => true, :activated => false}
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    raise Remote::PlayerNotFound, "error_code #{error_code}: #{message}" unless ['OK'].include?(error_code)
    return result_hash
  end
end
