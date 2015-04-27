class ShiftsController < ApplicationController
  layout 'cage'

  skip_before_filter :authenticate_user!, :only => :current

  def current
    @current_shift = current_shift.name
    respond_to do |format|
      format.html { render "shifts/current", :layout => false }
    end
  end

  def new
    return unless permission_granted? Shift.new, :roll
    @current_shift = current_shift

    @current_shift_name = @current_shift.name
    @current_accounting_date = @current_shift.accounting_date

    @next_shift_name = Shift.next_shift_name_by_name(@current_shift_name)
    if @current_shift_name == 'night'
      @next_accounting_date = @current_accounting_date + 1
    else
      @next_accounting_date = @current_accounting_date
    end
  end

  def create
    return unless permission_granted? Shift.new, :roll

    current_shift_id = params[:shift][:current_shift_id].to_i
    current_shift = Shift.find_by_id(current_shift_id)
    current_shift.roll!(1, current_user.id)

    redirect_to shifts_path
  end
end
