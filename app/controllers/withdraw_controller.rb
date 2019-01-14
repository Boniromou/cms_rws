class WithdrawController < FundController
  def new
    super
    @casino_id = current_casino_id
    @fund_type = @player.get_fund_type
    @payment_method = @player.payment_method_types
    @remain_limit = @player.remain_trans_amount(:withdraw, @casino_id)
  end
  
  def extract_params
    super
    @deposit_reason = "#{params[:player_transaction][:deposit_reason]}"
    if @deposit_reason != ""
      @data[:withdraw_remark] ="#{ @deposit_reason }"
    end
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date, source_type, machine_token)
    wallet_requester.withdraw(member_id, amount, ref_trans_id, trans_date, source_type, current_user.id, current_user.name, machine_token)
  end

  def check_transaction_acceptable
    super
    if @exception_transaction == 'no'
      validate_pin
    end
  end
  def create
    super
    redirect_to balance_path + "?member_id=#{@player.member_id}&exception_transaction=#{@exception_transaction}"
  end

end
