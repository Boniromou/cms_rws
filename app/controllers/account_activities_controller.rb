class AccountActivitiesController < ApplicationController
  layout 'cage'
  before_filter do |controller|
    authorize_action :account_activity, :list?
  end

  def search
  end

  def do_search
    begin
      raise SearchPlayerTransaction::NoIdNumberError if params[:id_number].blank?
      @end_time = Time.now.utc
      @start_time = @end_time - 1.day
      requester_helper.update_player(params[:id_type], params[:id_number])
      @player = policy_scope(Player).find_by_id_type_and_number(params[:id_type], params[:id_number])
      raise Remote::PlayerNotFound unless @player

      cage_response = wallet_requester.get_account_activity(@player.member_id, @start_time, @end_time)
      raise Remote::GetAccountActivityError unless cage_response.success?

      marketing_response = marketing_wallet_requester.get_account_activity(@player.member_id, @start_time, @end_time)
      raise Remote::GetAccountActivityError unless marketing_response.success?

      cage_transactions = get_cage_transactions_detail(cage_response.transactions)
      @transactions = marketing_response.transactions + cage_transactions
    rescue SearchPlayerTransaction::NoIdNumberError
      flash[:error] = "transaction_history.no_id"
    rescue Remote::PlayerNotFound
      @transactions = []
    rescue Remote::GetAccountActivityError
      flash[:error] = "account_activity.search_error"
    end
    respond_to do |format|
      format.html { render partial: "account_activities/search_result", formats: [:html] }
      format.js { render partial: "account_activities/search_result", formats: [:js] }
    end
  end

  protected
  def get_cage_transactions_detail(transactions)
    ref_trans_ids = transactions.map {|trans| trans[:ref_trans_id]}
    player_transactions = PlayerTransaction.where(ref_trans_id: ref_trans_ids).group_by(&:ref_trans_id)
    transactions.each do |trans|
      player_trans = player_transactions[trans[:ref_trans_id]] || []
      trans[:slip_number] = player_trans[0].try(:slip_number)
      trans[:zone_name], trans[:location_name] = get_zone_location(player_trans[0].try(:machine_token))
    end
  end

  def get_zone_location(machine_token)
    return nil, nil unless machine_token
    infos = machine_token.split('|')
    return infos[2], infos[4]
  end
end
