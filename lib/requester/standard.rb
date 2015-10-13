require File.expand_path(File.dirname(__FILE__) + "/base")

class Requester::Standard < Requester::Base
  ERROR_CODE_MAPPING = {
    "OK" => "Request is carried out successfully.",
    "InvalidLoginName" => "Invalide login name"
  }
  
  API_NAME_MAPPING = {
    :create_internal_player => 'create_internal_player',
    :deposit => 'deposit',
    :withdraw => 'withdraw',
    :query_player_balance => 'query_player_balance',
    :query_wallet_transactions => 'query_wallet_transactions'
  }

  RETRY_TIMES = 3

  def create_player(login_name, currency, player_id, player_currency_id)
    response = remote_rws_call('post', "#{@path}/#{get_api_name(:create_internal_player)}", :body => {:login_name => login_name, 
                                                                                                      :currency => currency, 
                                                                                                      :player_id => player_id, 
                                                                                                      :player_currency_id => player_currency_id})
    parse_create_player_response(response)
  end

  def get_player_balance(login_name, currency = nil, player_id = nil, player_currency_id = nil)
    create_player_proc = Proc.new {create_player(login_name, currency, player_id, player_currency_id)} unless player_id.nil?
    result = retry_call(RETRY_TIMES) do
      response = remote_rws_call('get', "#{@path}/#{get_api_name(:query_player_balance)}", :query => {:login_name => login_name})
      parse_get_player_balance_response(response, create_player_proc)
    end
    return 'no_balance' unless result.class == Float
    result
  end

  def deposit(login_name, amount, ref_trans_id, trans_date, shift_id, station_id, name)
    response = remote_rws_call('post', "#{@path}/#{get_api_name(:deposit)}", :body => {:login_name => login_name, :amt => amount,
                                                                                       :ref_trans_id => ref_trans_id, :trans_date => trans_date,
                                                                                       :shift_id => shift_id, :device_id => station_id,
                                                                                       :issuer_id => name})
    parse_deposit_response(response)
  end

  def withdraw(login_name, amount, ref_trans_id, trans_date, shift_id, station_id, name)
    response = remote_rws_call('post', "#{@path}/#{get_api_name(:withdraw)}", :body => {:login_name => login_name, :amt => amount,
                                                                                        :ref_trans_id => ref_trans_id, :trans_date => trans_date,
                                                                                        :shift_id => shift_id, :device_id => station_id,
                                                                                        :issuer_id => name})
    parse_withdraw_response(response)
  end

  protected
  def retry_call(retry_times, &block)
    begin
      return block.call
    rescue Exception => e
      #p e.message
      #p e.backtrace
      if retry_times > 0
        return retry_call(retry_times - 1, &block)
      else
        return e.message
      end
    end
  end
  
  def get_api_name(api_type)
    API_NAME_MAPPING[api_type]
  end

  def parse_get_player_balance_response(result, create_player_proc)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    create_player_proc.call if['InvalidLoginName'].include?(error_code) and !create_player_proc.nil?
    raise Remote::GetBalanceError, "#{error_code}" unless ['OK'].include?(error_code)
    raise Remote::GetBalanceError, 'balance is nil when OK' if result_hash[:balance].nil?
    return result_hash[:balance].to_f
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

  def parse_deposit_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s

    if ['OK'].include?(error_code)
      return 'OK'
    else
      raise Remote::DepositError, "error_code #{error_code}: #{ERROR_CODE_MAPPING[error_code]}"
    end
  end

  def parse_withdraw_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s

    if ['OK'].include?(error_code)
      return 'OK'
    elsif ['AmountNotEnough'].include?(error_code)
      raise Remote::AmountNotEnough, result_hash[:balance]
    else
      raise Remote::WithdrawError, "error_code #{error_code}: #{ERROR_CODE_MAPPING[error_code]}"
    end
  end
end
