class PlayerTransactionsController < ApplicationController
  layout 'cage'

  def print
    return unless permission_granted? PlayerTransaction.new, :print?
    AuditLog.print_log("print", current_user.employee_id, client_ip, sid,:description => {:station => current_station, :shift => current_shift.shift_type}) do
    end
    redirect_to home_path
  end
end
