class PlayerTransactionsController < ApplicationController
  layout 'cage'

  def index
  end

  def search
  end

  def do_search
      respond_to do |format|
        format.html { render partial: "player_transactions/search_result", formats: [:html] }
        format.js { render partial: "player_transactions/search_result", formats: [:js] }
      end
  end

  def print
    return unless permission_granted? PlayerTransaction.new, :print?
    AuditLog.print_log("print", current_user.employee_id, client_ip, sid,:description => {:station => current_station, :shift => current_shift.name}) do
    end
    redirect_to home_path
  end
end
