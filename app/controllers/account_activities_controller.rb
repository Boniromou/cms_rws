class AccountActivitiesController < ApplicationController
  layout 'cage'
  before_filter do |controller|
    authorize_action :account_activity, :list?
  end

  def search
    if params[:commit]
      begin
        raise SearchPlayerTransaction::NoIdNumberError if params[:id_number].blank?
        @round_id = params[:round_id]
        @end_time = Time.now.utc
        @start_time = @end_time - config_helper.account_activity_search_range.hours
        requester_helper.update_player(params[:id_type], params[:id_number])
        @player = policy_scope(Player).find_by_id_type_and_number(params[:id_type], params[:id_number])
        raise Remote::PlayerNotFound unless @player
        @transactions = []
      rescue SearchPlayerTransaction::NoIdNumberError
        flash[:error] = "transaction_history.no_id"
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
    respond_to do |format|
      format.json { render json: AccountActivityDatatable.new(requester_factory, params) }
    end
  end
end
