class CreditDepositController < FundController
  
  def extract_params
    super
    @duration = params[:duration].to_f
    @data[:duration] = @duration
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date, source_type)
  	credit_expired_at = Time.now.localtime + @duration.day
    wallet_requester.credit_deposit(member_id, amount, ref_trans_id, trans_date, credit_expired_at, source_type)
  end

  def new
    super
    @credit_life_time_array = config_helper.credit_life_time_array
    @credit_expired_at = Time.now.localtime + @credit_life_time_array[0].day
    @credit_limit = current_user.get_permission_value(:player_transaction, :add_credit) || 0
  end

  def create
    super
    redirect_to balance_path + "?member_id=#{@player.member_id}"
  end
end
