class FundController < ApplicationController
  include FundHelper

  layout 'cage'

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
    member_id = params[:player][:member_id]
    amount = params[:player_transaction][:amount]

    begin
      begin
        validate_amount_str( amount )
        server_amount = to_server_amount(amount)
        if operation_str == "fund_out"
          balance = Player.find_by_member_id(member_id).balance
          validate_balance_enough( server_amount, balance )
        end
      rescue Exception => e
        raise "invalid_amt." + action_str
      end
      AuditLog.fund_in_out_log(action_str, current_user.employee_id, client_ip, sid,:description => {:station => current_station, :shift => current_shift.name}) do
        @transaction = do_fund_action(member_id, server_amount)
      end
      @player = Player.find_by_member_id(member_id)
    rescue Exception => e
      puts e.message
      puts e.backtrace
      flash[:alert] = e.message
      flash[:fade_in] = false
      redirect_to :action => 'new', member_id: member_id
    end
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
