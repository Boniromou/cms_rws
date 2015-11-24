require File.expand_path(File.dirname(__FILE__) + "/standard")

class Requester::Wallet < Requester::Standard
  
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

  def credit_deposit(login_name, amount, ref_trans_id, trans_date)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('post', "#{@path}/credit_deposit", :body => {:login_name => login_name, 
                                                                              :amt => amount,
                                                                              :ref_trans_id => ref_trans_id, 
                                                                              :trans_date => trans_date})
      parse_credit_deposit_response(response)
    end
  end

  def credit_expire(login_name, amount, ref_trans_id, trans_date)
    retry_call(RETRY_TIMES) do
      response = remote_rws_call('post', "#{@path}/credit_expire", :body => {:login_name => login_name, 
                                                                        :amt => amount,
                                                                        :ref_trans_id => ref_trans_id, 
                                                                        :trans_date => trans_date})
      parse_credit_expire_response(response)
    end
  end

  protected

  def parse_get_player_balance_response(result, create_player_proc)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    message = result_hash[:error_msg].to_s || "no message"
    if['InvalidLoginName'].include?(error_code) and !create_player_proc.nil?
      create_player_proc.call
      raise Remote::RetryError.new({:balance => 'no_balance', :credit_balance => 'no_balance', :credit_expired_at => 'no_balance'}), "error_code #{error_code}: #{message}"
    end
    raise balance_no_result_error, "error_code #{error_code}: #{message}" unless ['OK'].include?(error_code)
    raise balance_no_result_error, 'balance is nil when OK' if result_hash[:balance].nil?
    return {:balance => result_hash[:balance].to_f, :credit_balance => result_hash[:credit_balance].to_f, :credit_expired_at => result_hash[:credit_expired_at]}
  end

  def balance_no_result_error
    Remote::GetBalanceError.new({:balance => 'no_balance', :credit_balance => 'no_balance', :credit_expired_at => 'no_balance'})
  end

  def parse_create_player_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    message = result_hash[:error_msg].to_s || "no message"
    raise Remote::CreatePlayerError, "error_code #{error_code}: #{message}" unless ['OK'].include?(error_code)
    return 'OK'
  end

  def parse_deposit_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    message = result_hash[:error_msg].to_s || "no message"
    raise Remote::DepositError, "error_code #{error_code}: #{message}}" unless ['OK','AlreadyProcessed'].include?(error_code)
    return 'OK'
  end

  def parse_withdraw_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    message = result_hash[:error_msg].to_s || "no message"
    raise Remote::AmountNotEnough.new(result_hash[:balance].to_f), "error_code #{error_code}: #{message}}" if ['AmountNotEnough'].include?(error_code)
    raise Remote::DepositError, "error_code #{error_code}: #{message}}" unless ['OK','AlreadyProcessed'].include?(error_code)
    return 'OK'
  end

  def parse_void_deposit_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    message = result_hash[:error_msg].to_s || "no message"
    raise Remote::AmountNotEnough.new(result_hash[:balance].to_f), "error_code #{error_code}: #{message}}" if ['AmountNotEnough'].include?(error_code)
    raise Remote::DepositError, "error_code #{error_code}: #{message}}" unless ['OK','AlreadyProcessed'].include?(error_code)
    return 'OK'
  end

  def parse_void_withdraw_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    message = result_hash[:error_msg].to_s || "no message"
    raise Remote::DepositError, "error_code #{error_code}: #{message}}" unless ['OK','AlreadyProcessed'].include?(error_code)
    return 'OK'
  end

  def parse_credit_deposit_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    message = result_hash[:error_msg].to_s || "no message"
    raise Remote::DepositError, "error_code #{error_code}: #{message}}" unless ['OK','AlreadyProcessed'].include?(error_code)
    return 'OK'
  end

  def parse_credit_expire_response(result)
    result_hash = remote_response_checking(result, :error_code)
    error_code = result_hash[:error_code].to_s
    message = result_hash[:error_msg].to_s || "no message"
    raise Remote::CreditNotEnough, result_hash[:credit_balance] if ['CreditNotEnough'].include?(error_code)
    raise Remote::CreditExpireError, "error_code #{error_code}: #{message}}" unless ['OK','AlreadyProcessed'].include?(error_code)
    return 'OK'
  end
end
