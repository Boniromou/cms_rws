class AccountActivitiesController < ApplicationController
  include FormattedTimeHelper
  layout 'cage'
  before_filter do |controller|
    authorize_action :account_activity, :list?
  end

  def search
    if params[:commit]
      begin
        @end_time = Time.now.utc
        @start_time = @end_time - config_helper.account_activity_search_range.hours
        params[:selected_tab_index] == '0' ? search_by_member : search_by_round
        @transactions = []
      rescue SearchPlayerTransaction::NoIdNumberError => e
        flash[:error] = e.message
      rescue Remote::PlayerNotFound
        flash[:error] = "search_error.not_found"
      end
      respond_to do |format|
        format.html { render partial: "account_activities/search_result", formats: [:html] }
        format.js { render partial: "account_activities/search_result", formats: [:js] }
      end
    end
  end

  def do_search
    result = AccountActivityDatatable.new(requester_factory, params).as_json
    if result[:player_id]
      player = policy_scope(Player).find_by_id(result[:player_id])
      result.merge!({member_id: player.member_id, licensee_name: player.licensee.name, start_time: format_time(params[:start_time]), end_time: format_time(params[:end_time])}) if player
    end
    result.merge!(start: params[:start], length: params[:length])
    respond_to do |format|
      format.json { render json: result }
    end
  end

  protected

  def search_by_member
    raise SearchPlayerTransaction::NoIdNumberError.new("transaction_history.no_id") if params[:id_number].blank?
    requester_helper.update_player(params[:id_type], params[:id_number])
    @player = policy_scope(Player).find_by_id_type_and_number(params[:id_type], params[:id_number])
    raise Remote::PlayerNotFound unless @player
    @member_id = @player.member_id
  end

  def search_by_round
    raise SearchPlayerTransaction::NoIdNumberError.new("account_activity.no_round_id") if params[:round_id].blank?
    @round_id = params[:round_id]
  end
end
