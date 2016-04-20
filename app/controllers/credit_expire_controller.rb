class CreditExpireController < FundController
  def call_wallet(member_id, amount, ref_trans_id, trans_date)
    wallet_requester.credit_expire(member_id, amount, ref_trans_id, trans_date)
  end

  def new
  	super
  	balance_response = wallet_requester.get_player_balance(@member_id, @player.currency.name, @player.id, @player.currency_id)
    @player_balance = balance_response.balance
    @credit_balance = balance_response.credit_balance
    @credit_expired_at = balance_response.credit_expired_at
  end

  def create
    super
    redirect_to balance_path + "?member_id=#{@player.member_id}"
  end
end
