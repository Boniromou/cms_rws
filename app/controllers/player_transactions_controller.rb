class PlayerTransactionsController < ApplicationController
  layout 'cage'

  def search
    return unless permission_granted? PlayerTransaction.new, :search?
  end

  def do_search
    return unless permission_granted? PlayerTransaction.new, :search?
    begin
      id_type = params[:id_type]
      id_number = params[:id_number]
      transaction_id = params[:transaction_id]
      start_time = params[:start_time] unless params[:start_time].blank?
      end_time = params[:end_time] unless params[:end_time].blank?
      @player_transactions = PlayerTransaction.search_query(id_type, id_number, transaction_id, start_time, end_time)
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
end
