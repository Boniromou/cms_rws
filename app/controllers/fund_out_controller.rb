class FundOutController < ApplicationController
  include FundHelper

  layout 'cage'

  def new
    return unless check_permission PlayerTransaction.new, :withdraw?
    member_id = params[:member_id]
    @operation = "fund_out"
    @player = Player.find_by_member_id(member_id)
  end

  def create
    return unless check_permission PlayerTransaction.new, :withdraw?
    member_id = params[:player][:member_id]
    amount = params[:player_transaction][:amount]

    begin
      begin
        validate_amount_str( amount )
        server_amount = to_server_amount(amount)
        balance = Player.find_by_member_id(member_id).balance
        validate_balance_enough( server_amount, balance )
      rescue Exception => e
        raise "invalid_amt.withdrawal"
      end
      AuditLog.fund_in_out_log("withdrawal", current_user.employee_id, client_ip, sid,:description => {:station => station, :shift => current_shift.shift_type}) do
        @transaction = do_fund_out(member_id, server_amount)
      end
      @player = Player.find_by_member_id(member_id)
    rescue Exception => e
      flash[:alert] = e.message
      redirect_to :action => 'new', member_id: member_id
    end
  end

  protected

  def do_fund_out(member_id, amount)
    transaction = nil
    Player.transaction do
      Player.fund_out(member_id, amount)
      transaction = PlayerTransaction.save_fund_out_transaction(member_id, amount, current_shift.id, current_user.id, station)
    end
    transaction
  end
end
