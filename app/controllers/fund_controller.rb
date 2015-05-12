class FundController < ApplicationController
  include FundHelper

  layout 'cage'
  rescue_from AmountInvalidError, :with => :handle_amount_invalid_error

  def operation_sym
    raise NotImplementedError
  end

  def operation_str
    raise NotImplementedError
  end

  def action_str
    raise NotImplementedError
  end

  def new
    return unless permission_granted? PlayerTransaction.new, operation_sym
    member_id = params[:member_id]
    @operation = operation_str
    @player = Player.find_by_member_id(member_id)
  end

  def create
    return unless permission_granted? PlayerTransaction.new, operation_sym
    @member_id = params[:player][:member_id]
    @player = Player.find_by_member_id(@member_id)
    amount = params[:player_transaction][:amount]
    server_amount = get_server_amount(amount)
    AuditLog.fund_in_out_log(action_str, current_user.employee_id, client_ip, sid,:description => {:station => current_station, :shift => current_shift.name}) do
      @transaction = do_fund_action(@member_id, server_amount)
    end
  end

  def get_server_amount(amount)
    validate_amount_str(amount)
    to_server_amount(amount)
  end

  def handle_amount_invalid_error(e)
    handle_fund_error("invalid_amt." + action_str)
  end

  def handle_fund_error(msg)
    flash[:alert] = msg
    flash[:fade_in] = false
    redirect_to :action => 'new', member_id: @member_id
  end

  protected

  def do_fund_action(member_id, amount)
    transaction = nil
    Player.transaction do
      Player.send operation_str, member_id, amount
      transaction = PlayerTransaction.send "save_#{operation_str}_transaction", member_id, amount, current_shift.id, current_user.id, current_station_id
    end
    transaction
  end
end
