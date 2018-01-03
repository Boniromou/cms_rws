require File.expand_path(File.dirname(__FILE__) + "/base")

class Requester::MarketingWallet < Requester::Base

  def get_account_activity(login_name, start_time, end_time)
    result = retry_call(RETRY_TIMES) do
      response = remote_rws_call('get', "#{@path}/get_account_activity", 
        :query => {:login_name => login_name,
                   :licensee_id => @licensee_id,
                   :start_time => start_time,
                   :end_time => end_time})
      parse_get_account_activity_response(response)
    end
    result
  end

  protected
  def parse_get_account_activity_response(result)
    result_hash = remote_response_checking(result, :error_code)
    response = Requester::GetAccountActivityResponse.new(result_hash)
    raise Remote::GetAccountActivityError.new(Requester::NoAccountActivityResponse.new) unless response.success?
    return response
  end
end
