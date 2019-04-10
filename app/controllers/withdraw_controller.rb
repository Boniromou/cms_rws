class WithdrawController < FundController
  def new
    super
    @casino_id = current_casino_id
    @fund_type = @player.get_fund_type
    @payment_method = @player.payment_method_types
    @remain_limit = @player.remain_trans_amount(:withdraw, @casino_id)
    @authorized_amount = @config_helper.withdraw_authorized_amount
    if @exception_transaction != 'yes' && cookies[:second_auth_result].present? && cookies[:second_auth_info].present?
      auth_info = second_auth_info
      auth_result = second_auth_result
      raise FundInOut::AuthorizationFail if auth_result[:error_code] != 'OK' || auth_result[:message_id] != auth_info[:message_id]

      auth_info = auth_info[:auth_info].recursive_symbolize_keys!
      @authorize_result = 'yes'
      @payment_method_type = auth_info[:payment_method_type]
      @player_transaction_amount = auth_info[:player_transaction][:amount]
      @deposit_reason = auth_info[:player_transaction][:deposit_reason]
      flash[:success] = 'flash_message.authorize_success' unless flash[:fail]
    end
  end

  def extract_params
    super
    @deposit_reason = "#{params[:player_transaction][:deposit_reason]}"
    if @deposit_reason != ""
      @data[:withdraw_remark] ="#{ @deposit_reason }"
    end
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date, source_type, machine_token)
    wallet_requester.withdraw(member_id, amount, ref_trans_id, trans_date, source_type, current_user.uid, current_user.name, machine_token)
  end

  def check_transaction_acceptable
    super
    if @exception_transaction == 'no'
      validate_pin
    end
  end

  def auth_callback_url
    "#{URL_BASE}/fund_out?member_id=#{@player.member_id}&exception_transaction=#{@exception_transaction}"
  end
end
