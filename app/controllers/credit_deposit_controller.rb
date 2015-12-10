class CreditDepositController < FundController
  def call_wallet(member_id, amount, ref_trans_id, trans_date)
  	credit_expired_at = Time.now.localtime + config_helper.credit_life_time
    wallet_requester.credit_deposit(member_id, amount, ref_trans_id, trans_date, credit_expired_at)
  end

   def new
  	super
    @credit_expired_at = Time.now.localtime + config_helper.credit_life_time
  end
end
