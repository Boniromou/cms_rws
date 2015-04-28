class PlayerTransactionsController < ApplicationController
  layout 'cage'
  include FormattedTimeHelper

  def search
    return unless permission_granted? PlayerTransaction.new, :search?
  end

  def do_search
    return unless permission_granted? PlayerTransaction.new, :search?
    begin
      id_type = params[:id_type]
      id_number = params[:id_number]
      start_time = parse_datetime(params[:start_time]).utc unless params[:start_time].blank?
      end_time = parse_datetime(params[:end_time]).utc unless params[:end_time].blank?
      transaction_id = params[:transaction_id]
      @player_transactions = PlayerTransaction.search_query(id_type, id_number, start_time, end_time, transaction_id)
      respond_to do |format|
        format.html { render partial: "player_transactions/search_result", formats: [:html] }
        format.js { render partial: "player_transactions/search_result", formats: [:js] }
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace
      respond_to do |format|
        format.html { render partial: "player_transactions/search_result", formats: [:html] }
        format.js { render partial: "player_transactions/search_result", formats: [:js] }
      end

    end
  end

  def print
    return unless permission_granted? PlayerTransaction.new, :print?
    AuditLog.print_log("print", current_user.employee_id, client_ip, sid,:description => {:station => current_station, :shift => current_shift.name}) do
    end
    redirect_to home_path
  end

  def reprint
    @transaction = PlayerTransaction.first
    @player = Player.first
  end
end
