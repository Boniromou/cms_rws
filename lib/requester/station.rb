require File.expand_path(File.dirname(__FILE__) + "/base")

class Requester::Station < Requester::Standard
  def initialize(base_path)
      config = Hood::CONFIG
      @lax_requester = LaxSupport::AuthorizedRWS::LaxRWS.new(config.internal_property_id, config.service_id, config.service_key)
      @lax_requester.timeout = 5
      @path = base_path
  end

  def validate_machine_token(machine_token, property_id)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('get', "#{@path}/validate_machine_token", :query => {:machine_token => machine_token,
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
