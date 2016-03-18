require File.expand_path(File.dirname(__FILE__) + "/base")

class Requester::Station < Requester::Base

  def validate_machine_token(machine_type, machine_token, property_id, casino_id)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('get', "#{@path}/validate_machine_token", :query => {:machine_type => machine_type,
                                                                                      :machine_token => machine_token,
                                                                                      :property_id => property_id,
                                                                                      :casino_id => casino_id})
      parse_validate_machine_token_response(response)
    end
  end

  protected
  def parse_validate_machine_token_response(result)
    result_hash = remote_response_checking(result, :error_code)
    response = Requester::StationResponse.new(result_hash)
    return response
  end
end
