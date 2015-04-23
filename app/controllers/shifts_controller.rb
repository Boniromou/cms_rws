class ShiftsController < ApplicationController
  layout 'cage'

  skip_before_filter :authenticate_user!, :only => :current

  def current
    @current_shift = ShiftType.find_by_id(current_shift.shift_type_id).name
    respond_to do |format|
      format.html { render "shifts/current", :layout => false }
    end
  end

  def new
  end
end
