class FundInController < ApplicationController
  include FundHelper

  layout 'cage'

  def new
    return unless check_permission PlayerTransaction.new, :deposit?
    member_id = params[:member_id]
    @operation = "fund_in"
    @player = Player.find_by_member_id(member_id)
  end

  def create
    return unless check_permission PlayerTransaction.new, :deposit?
    member_id = params[:player][:member_id]
    amount = params[:player_transaction][:amount]

    begin
      begin
        validate_amount_str( amount )
        server_amount = to_server_amount(amount)
      rescue Exception => e
        raise "invalid_amt.deposit"
      end
      AuditLog.fund_in_out_log("deposit", current_user.employee_id, client_ip, sid,:description => {:station => current_station, :shift => current_shift.shift_type}) do
        @transaction = do_fund_in(member_id, server_amount)
      end
      @player = Player.find_by_member_id(member_id)
    rescue Exception => e
      flash[:alert] = e.message
      redirect_to :action => 'new', member_id: member_id
    end
  end

  protected

  def do_fund_in(member_id, amount)
    transaction = nil
    Player.transaction do
      Player.fund_in(member_id, amount)
      transaction = PlayerTransaction.save_fund_in_transaction(member_id, amount, current_shift.id, current_user.id, current_station)
    end
    transaction
  end
end
