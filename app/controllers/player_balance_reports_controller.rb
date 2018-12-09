class PlayerBalanceReportsController < ApplicationController
  include FundHelper
  include FormattedTimeHelper

  layout 'cage'
  before_filter do |controller|
    authorize_action :player_balance_report, :list?
  end

  def search
    get_total_balances
  end

  def do_search
    options = {licensee_id: current_licensee_id, wallet_requester: requester_factory.get_wallet_requester }
    result = PlayerBalanceReportDatatable.new(view_context, params.merge(options))
    respond_to do |format|
      format.json { render json: result }
    end
  end

  protected
  def get_total_balances
    result = requester_factory.get_wallet_requester.get_total_balances
    @total_balances = display_balance(result.total_balances)
    @data_updated_to = format_time(Time.now)
  end
end
