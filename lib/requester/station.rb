require File.expand_path(File.dirname(__FILE__) + "/base")

class Requester::Station < Requester::Base
  def initialize(property_id, secret_access_key, base_path, servicd_id)
      @lax_requester = LaxSupport::AuthorizedRWS::LaxRWS.new(property_id, servicd_id, secret_access_key)
      @lax_requester.timeout = 5
      @path = base_path
  end

  def validate_machine_token(machine_type, machine_token, property_id)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('get', "#{@path}/validate_machine_token", :query => {:machine_type => machine_type,
                                                                                      :machine_token => machine_token,
                                                                                      :property_id => property_id})
      parse_validate_machine_token_response(response)
    end
  end

  protected
  def parse_validate_machine_token_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    return result_hash
  end
end
