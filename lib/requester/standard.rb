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
    :query_wallet_transactions => 'query_wallet_transactions',
    :retrieve_location_info => 'retrieve_location_info'
  }

  def retrieve_location_info(terminal_id)
    # response = remote_rws_call('get', "#{@path}/#{get_api_name(:retrieve_location_info)}", :query => {:terminal_id => terminal_id})
    # parse_retrieve_location_info_response(response)
    return nil if terminal_id == 'x'
    'LOCATION10-STATION10'
  end

  def create_player(login_name, currency, player_id, player_currency_id)
    response = remote_rws_call('post', "#{@path}/#{get_api_name(:create_internal_player)}", :body => {:login_name => login_name, 
                                                                                                      :currency => currency, 
                                                                                                      :player_id => player_id, 
                                                                                                      :player_currency_id => player_currency_id})
    parse_create_player_response(response)
  end

  def get_player_balance(login_name)
    response = remote_rws_call('get', "#{@path}/#{get_api_name(:query_player_balance)}", :query => {:login_name => login_name})
    parse_get_player_balance_response(response)
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
  
  def get_api_name(api_type)
    API_NAME_MAPPING[api_type]
  end

  def parse_retrieve_location_info_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s

    if ['OK'].include?(error_code)
      return 'OK'
    end
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

  def parse_lock_player_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s

    if ['OK', 'AlreadyLocked'].include?(error_code)
      return 'OK'
    else
      raise Remote::LockPlayerError, "error_code #{error_code}: #{ERROR_CODE_MAPPING[error_code]}"
    end
  end

  def parse_unlock_player_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s

    if ['OK', 'AlreadyUnlocked'].include?(error_code)
      return 'OK'
    else
      raise Remote::UnlockPlayerError, "error_code #{error_code}: #{ERROR_CODE_MAPPING[error_code]}"
    end
  end
end
