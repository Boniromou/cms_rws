require File.expand_path(File.dirname(__FILE__) + "/base")

class Requester::Standard < Requester::Base
  ERROR_CODE_MAPPING = {
    "OK" => "Request is carried out successfully.",
    "InvalidLoginName" => "Invalide login name"
  }
  
  API_NAME_MAPPING = {
    :create_player => 'create_player',
    :lock_player => 'lock_player',
    :unlock_player => 'unlock_player',
    :deposit => 'deposit',
    :withdraw => 'withdraw',
    :query_player_balance => 'query_player_balance',
    :query_wallet_transactions => 'query_wallet_transactions'
  }

  def create_player(login_name, currency)
    response = remote_rws_call('post', "#{@path}/#{get_api_name(:create_player)}", :body => {:login_name => login_name, :currency => currency})
    parse_create_player_response(response)
  end

  def get_player_balance(member_id)
    login_name = member_id
    response = remote_rws_call('get', "#{@path}/#{get_api_name(:query_player_balance)}", :query => {:login_name => login_name})
    parse_get_player_balance_response(response)
  end

  protected
  
  def get_api_name(api_type)
    API_NAME_MAPPING[api_type]
  end

  def parse_get_player_balance_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s

    if ['OK'].include?(error_code)
      raise Remote::GetBalanceError, 'balance is nil' if result_hash[:balance].nil?
      result_hash[:balance].to_f
    else
      raise Remote::GetBalanceError, "error_code #{error_code}: #{ERROR_CODE_MAPPING[error_code]}"
    end
  end

  def parse_create_player_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s

    if ['OK'].include?(error_code)
      return 'OK'
    else
      raise Remote::CreatePlayerError, "error_code #{error_code}: #{ERROR_CODE_MAPPING[error_code]}"
    end
  end
end
