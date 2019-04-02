class MergeController < FundController
  include SearchHelper
  def new
    super
    @casino_id = current_casino_id
    @remain_limit = @player.remain_trans_amount(:deposit, @casino_id)
    @fund_type = @player.get_fund_type
    @payment_method = @player.payment_method_types
  end
  
  def merge_player
    sur_member_id = params[:player][:sur_member_id]
    vic_member_id = params[:player][:vic_member_id]
    @player_sur = policy_scope(Player).find_by_member_id(sur_member_id) 
    @player_vic = policy_scope(Player).find_by_member_id(vic_member_id)
    @amount = params[:player_transaction][:sur_amount]
    @amount2 = params[:player_transaction][:vic_amount]
    validate_amount_str(@amount2)
    @server_amount = to_server_amount(@amount2)
    @ref_trans_id = nil
    @payment_method_type = params[:payment_method_type]
    @source_of_funds = params[:source_of_funds]
    
    @transaction = create_deposit_transaction(@player_sur.member_id, @server_amount, @ref_trans_id, @data.to_yaml)
    @transaction2 = create_withdraw_transaction(@player_vic.member_id, @server_amount, @ref_trans_id, @data.to_yaml)
   
    puts Approval::Request::PENDING
    response = Approval::Models.submit('player', @player_vic.id, 'merge_player', get_submit_data, @current_user.name)   
    @player_vic.lock_account!('cage_lock')    
 
    flash[:success] = {key: "flash_message.merge_complete", replace: {vic_player: @player_vic.member_id, sur_player: @player_sur.member_id}}
    redirect_to players_search_merge_path(operation: :merge)
  end
   
  def create_deposit_transaction(member_id, amount, ref_trans_id = nil, data = nil)
    raise FundInOut::InvalidMachineToken unless current_machine_token
    PlayerTransaction.send "save_deposit_transaction", member_id, amount, current_shift.id, current_user.id, current_machine_token, ref_trans_id, data
  end

  def create_withdraw_transaction(member_id, amount, ref_trans_id = nil, data = nil)
    raise FundInOut::InvalidMachineToken unless current_machine_token 
    PlayerTransaction.send "save_withdraw_transaction", member_id, amount, current_shift.id, current_user.id, current_machine_token, ref_trans_id, data
  end
  
  def get_submit_data
    {
      :licensee_id => Licensee.find_by_id(@player_sur.licensee_id).name,
      :player_vic_id => @player_vic.member_id,
      :player_vic_before_amount => @amount2,
      :minus_amount => @amount2.to_str,
      :player_vic_after_balance => 0,
      :player_sur_id => @player_sur.member_id,
      :player_sur_before_amount => @amount,
      :amount => @amount2,
      :player_sur_after_amount => @amount.to_f + @amount2.to_f,
      :transaction => [@transaction.id, @transaction2.id]
    }  
  end

  def call_wallet(member_id, amount, ref_trans_id, trans_date, source_type, machine_token)
    wallet_requester.deposit(member_id, amount, ref_trans_id, trans_date, source_type, current_user.uid, current_user.name, machine_token)
  end

  def extract_params
    super
    @deposit_reason = "#{params[:player_transaction][:deposit_reason]}"
    if @deposit_reason != ""
      @data[:deposit_remark] = @deposit_reason
    end
  end
  
  def search
    @operation = params[:operation]
    @card_id = params[:card_id] 
  end
 
end

