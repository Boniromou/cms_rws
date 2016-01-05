require File.expand_path(File.dirname(__FILE__) + "/base")

class Requester::Wallet < Requester::Base
  
  def create_player(login_name, currency, player_id, player_currency_id)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('post', "#{@path}/create_internal_player", :body => {:login_name => login_name, 
                                                                                      :currency => currency, 
                                                                                      :player_id => player_id, 
                                                                                      :player_currency_id => player_currency_id})
      parse_create_player_response(response)
    end
  end

  def get_player_balance(login_name, currency = nil, player_id = nil, player_currency_id = nil)
    create_player_proc = Proc.new {create_player(login_name, currency, player_id, player_currency_id)} unless player_id.nil?
    result = retry_call(RETRY_TIMES) do
      response = remote_rws_call('get', "#{@path}/query_player_balance", :query => {:login_name => login_name})
      parse_get_player_balance_response(response, create_player_proc)
    end
    result
  end

  def deposit(login_name, amount, ref_trans_id, trans_date)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('post', "#{@path}/deposit", :body => {:login_name => login_name, 
                                                                       :amt => amount,
                                                                       :ref_trans_id => ref_trans_id, 
                                                                       :trans_date => trans_date})
      parse_deposit_response(response)
    end
  end

  def withdraw(login_name, amount, ref_trans_id, trans_date)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('post', "#{@path}/withdraw", :body => {:login_name => login_name, 
                                                                        :amt => amount,
                                                                        :ref_trans_id => ref_trans_id, 
                                                                        :trans_date => trans_date})
      parse_withdraw_response(response)
    end
  end

  def void_deposit(login_name, amount, ref_trans_id, trans_date)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('post', "#{@path}/void_deposit", :body => {:login_name => login_name, 
                                                                            :amt => amount,
                                                                            :ref_trans_id => ref_trans_id, 
                                                                            :trans_date => trans_date})
      parse_void_deposit_response(response)
    end
  end

  def void_withdraw(login_name, amount, ref_trans_id, trans_date)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('post', "#{@path}/void_withdraw", :body => {:login_name => login_name, 
                                                                             :amt => amount,
                                                                             :ref_trans_id => ref_trans_id, 
                                                                             :trans_date => trans_date})
      parse_void_withdraw_response(response)
    end
  end

  def credit_deposit(login_name, amount, ref_trans_id, trans_date, credit_expired_at)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('post', "#{@path}/credit_deposit", :body => {:login_name => login_name, 
                                                                              :credit_amt => amount,
                                                                              :ref_trans_id => ref_trans_id, 
                                                                              :trans_date => trans_date,
                                                                              :credit_expired_at => credit_expired_at})
      parse_credit_deposit_response(response)
    end
  end

  def credit_expire(login_name, amount, ref_trans_id, trans_date)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('post', "#{@path}/credit_expire", :body => {:login_name => login_name, 
                                                                        :credit_amt => amount,
                                                                        :ref_trans_id => ref_trans_id, 
                                                                        :trans_date => trans_date})
      parse_credit_expire_response(response)
    end
  end

  protected

  def parse_get_player_balance_response(result, create_player_proc)
    begin
      result_hash = remote_response_checking(result, :error_code)
    rescue Remote::UnexpectedResponseFormat => e
      raise Remote::NoBalanceError.new(Requester::NoBalanceResponse.new),"UnexpectedResponseFormat"
    end
    response = Requester::GetPlayerBalanceResponse.new(result_hash)
    if response.invalid_login_name? and !create_player_proc.nil?
      create_player_proc.call
      raise Remote::RetryError.new(Requester::NoBalanceResponse.new), response.exception_msg
    end
    raise Remote::NoBalanceError.new(Requester::NoBalanceResponse.new), response.exception_msg unless response.success?
    return response
  end

  def parse_create_player_response(result)
    result_hash = remote_response_checking(result, :error_code)
    response = Requester::WalletResponse.new(result_hash)
    raise Remote::CreatePlayerError, response.exception_msg unless response.success?
    return response
  end

  def parse_deposit_response(result)
    result_hash = remote_response_checking(result, :error_code)
    response = Requester::WalletTransactionResponse.new(result_hash)
    raise Remote::DepositError, response.exception_msg unless response.success?
    return response
  end

  def parse_withdraw_response(result)
    result_hash = remote_response_checking(result, :error_code)
    response = Requester::WalletTransactionResponse.new(result_hash)
    raise Remote::AmountNotEnough.new(response.balance), response.exception_msg if response.amount_not_enough?
    raise Remote::WithdrawError, response.exception_msg unless response.success?
    return response
  end

  def parse_void_deposit_response(result)
    result_hash = remote_response_checking(result, :error_code)
    response = Requester::WalletTransactionResponse.new(result_hash)
    raise Remote::AmountNotEnough.new(response.balance), response.exception_msg if response.amount_not_enough?
    raise Remote::DepositError, response.exception_msg unless response.success?
    return response
  end

  def parse_void_withdraw_response(result)
    result_hash = remote_response_checking(result, :error_code)
    response = Requester::WalletTransactionResponse.new(result_hash)
    raise Remote::WithdrawError, response.exception_msg unless response.success?
    return response
  end

  def parse_credit_deposit_response(result)
    result_hash = remote_response_checking(result, :error_code)
    response = Requester::WalletTransactionResponse.new(result_hash)
    raise Remote::CreditNotExpired, response.exception_msg if response.credit_not_expired?
    raise Remote::DepositError, response.exception_msg unless response.success?
    return response
  end

  def parse_credit_expire_response(result)
    result_hash = remote_response_checking(result, :error_code)
    response = Requester::WalletTransactionResponse.new(result_hash)
    raise Remote::CreditNotExpired, response.exception_msg if response.amount_not_match?
    raise Remote::DepositError, response.exception_msg unless response.success?
    return response
  end
end
