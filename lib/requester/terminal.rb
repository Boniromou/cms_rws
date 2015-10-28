require File.expand_path(File.dirname(__FILE__) + "/base")

class Requester::Terminal < Requester::Standard
  
  def retrieve_location_info(terminal_id)
    # response = remote_rws_call('get', "#{@path}/#{get_api_name(:retrieve_location_info)}", :query => {:terminal_id => terminal_id})
    # parse_retrieve_location_info_response(response)
    return nil if terminal_id == 'x'
    'LOCATION10-STATION10'
  end

  protected
  def parse_retrieve_location_info_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s

    if ['OK'].include?(error_code)
      return 'OK'
    end
  end
end
