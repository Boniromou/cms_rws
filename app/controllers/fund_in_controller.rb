class FundInController < ApplicationController
  include FundHelper

  layout 'cage'

  def new
    member_id = params[:member_id]
    @player = Player.find_by_member_id(member_id)
  end

  def create
    member_id = params[:player][:member_id]
    amount = params[:player_transaction][:amount]

    begin
      validate_amount_str( amount )
      server_amount = to_server_amount(amount)
      do_fund_in(member_id, server_amount)
      @transaction = {member_id: member_id, amount: server_amount}
    rescue Exception => e
      flash[:alert] = e.message
      redirect_to :action => 'new', member_id: member_id
    end
  end

  protected

  def do_fund_in(member_id, amount)
    #TODO do it in db transaction
    Player.fund_in(member_id, amount)
    PlayerTransaction.save_fund_in_transaction(member_id, amount)
  end
end
