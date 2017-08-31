require File.expand_path(File.dirname(__FILE__) + "/base")

class Requester::Marketing < Requester::Base

  def create_mp_player(player_id, member_id, card_id, status, test_mode_player, licensee_id, currency_id, blacklist)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('post', "#{@path}/internal/create_player", :body => {:id => player_id, 
                                                                                      :member_id => member_id, 
                                                                                      :card_id => card_id,
                                                                                      :status => status, 
                                                                                      :test_mode_player => test_mode_player,
                                                                                      :licensee_id => licensee_id, 
                                                                                      :currency_id => currency_id,
                                                                                      :blacklist => blacklist})
      parse_create_player_response(response)
    end
  end

  protected
  def parse_create_player_response(result)
    result_hash = remote_response_checking(result, :error_code)
    response = Requester::WalletResponse.new(result_hash)
    raise Remote::CreatePlayerError, response.exception_msg unless response.success?
    return response
  end
end
