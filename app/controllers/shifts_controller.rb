class ShiftsController < ApplicationController
  layout 'cage'

  skip_before_filter :check_session_expiration, :authenticate_user!,:pass_terminal_id, :only => :current

  include FormattedTimeHelper

  def current
    @current_shift = current_shift.name
    respond_to do |format|
      format.html { render "shifts/current", :layout => false }
    end
  end

  def new
    return unless permission_granted? Shift.new, :roll?

    @current_shift = current_shift

    @current_shift_name = @current_shift.name
    @current_accounting_date = @current_shift.accounting_date

    @next_shift_name = Shift.next_shift_name_by_name(@current_shift_name)
    @next_accounting_date = AccountingDate.next_shift_accounting_date(@current_shift_name, @current_accounting_date)
  end

  def create
    return unless permission_granted? Shift.new, :roll?

    begin
      current_shift_id = params[:shift][:current_shift_id].to_i
      current_shift = Shift.find_by_id(current_shift_id)

      AuditLog.shift_log("roll_shift", current_user.name, client_ip, sid, :description => {:station => current_station, :shift => current_shift.name}) do
        #TODO: Station id
        current_shift.roll!(current_station_id, current_user.id)
      end

      flash[:success] = { key: "shift.roll_success", replace: { timestamp: format_time(current_shift.roll_shift_at) } }
      redirect_to :controller => 'front_money', :action => 'search', :accounting_date => current_shift.accounting_date, :shift_name => current_shift.name
    rescue Exception => ex
      flash[:error] = "shift." + ex.message
      redirect_to shifts_path
    end
  end
end
