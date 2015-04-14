class PlayerTransactionsController < ApplicationController
  layout 'cage'

  def print
#    return unless check_permission PlayerTransaction.new, :print?
    AuditLog.print_log("print", current_user.employee_id, client_ip, sid,:description => {:station => station, :shift => current_shift.shift_type}) do
    end
    redirect_to home_path
  end
end
