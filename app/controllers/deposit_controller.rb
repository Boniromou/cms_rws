class DepositController < FundController
  include SearchHelper
  def new
    super
    @casino_id = current_casino_id
    @remain_limit = @player.remain_trans_amount(:deposit, @casino_id)
    @fund_type = @player.get_fund_type(@casino_id)
    @payment_method = @player.payment_method_types(@casino_id)
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date, source_type, machine_token)
    wallet_requester.deposit(member_id, amount, ref_trans_id, trans_date, source_type, current_user.uid, current_user.name, machine_token)
  end
  
  def extract_params
    super
#    @is_player_deposit = params[:player_transaction][:non_player_deposit] == "0"
    @deposit_reason = params[:player_transaction][:deposit_reason]
#    @data[:is_player_deposit] = @is_player_deposit
    @data[:remark] = @deposit_reason
  end
  
  def search
    @operation = params[:operation]
    @card_id = params[:card_id] 
  end
 
  def get_start_time(time_str)
    player_trans_controller = PlayerTransactionsController.new
    start_time = player_trans_controller.get_start_time    
  end
end
