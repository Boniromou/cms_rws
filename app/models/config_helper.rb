class ConfigHelper

  def initialize(casino_id)
    @casino_id = casino_id
  end

  def retrieve_config(key)
    configuration = Configuration.find_by_key_and_casino_id(key, @casino_id)
    return configuration.value if configuration
    nil
  end

  def source_of_funds
    retrieve_config('source_of_funds').split(',')
  end
  
  def payment_method_types
    retrieve_config('payment_method_types').split(',')
  end

  def trans_history_search_range
    retrieve_config('trans_history_search_range').to_i
  end

  def polling_time
    retrieve_config('polling_time').to_i * 60000
  end

  def audit_log_search_range
    retrieve_config('audit_log_search_range').to_i
  end

  def change_log_search_range
    retrieve_config('change_log_search_range').to_i
  end

  def account_activity_search_range
    retrieve_config('account_activity_search_range').to_i
  end

  def token_life_time
    retrieve_config('token_life_time').to_i * 60
  end

  def session_expiration_time
    life_time = retrieve_config('session_life_time') || 60
    life_time.to_i * 60
  end

  def credit_life_time_array
    retrieve_config('credit_life_time_array').split(',').map{|t| t.to_f}
  end
  
  def roll_shift_time
    Configuration.find_by_key_and_casino_id('roll_shift_time', @casino_id).value
  end

  def pin_log_search_range
    retrieve_config('pin_log_search_range').to_i
  end

  def transaction_void_range
    retrieve_config('transaction_void_range').to_i
  end

  def daily_deposit_limit
    retrieve_config('daily_deposit_limit').to_i
  end

  def daily_withdraw_limit
    retrieve_config('daily_withdraw_limit').to_i
  end
end
