class CreditDepositController < FundController
  
  def extract_params
    super
    @duration = params[:duration].to_f
    @data = {:remark => params[:player_transaction][:remark], :duration => @duration}
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date)
  	credit_expired_at = Time.now.localtime + @duration.day
    wallet_requester.credit_deposit(member_id, amount, ref_trans_id, trans_date, credit_expired_at)
  end

  def new
    super
    @credit_expired_at = Time.now.localtime + config_helper.credit_life_time
    @credit_life_time_array = [0.5,1,3,5,7]
  end

  def create
    super
    redirect_to balance_path + "?member_id=#{@player.member_id}"
  end
end
