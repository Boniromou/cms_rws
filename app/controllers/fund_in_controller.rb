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

    if amount_valid?( amount )
      amount = to_server_amount( amount )

      player = Player.find_by_member_id(member_id)
      player[:balance] += amount
      player.save

      @transaction = PlayerTransaction.new
      @transaction[:player_id] = player[:id]
      @transaction[:amount] = amount
      @transaction.save
    else
      flash[:alert] = "Input amount not valid"
      redirect_to :action => 'new', member_id: member_id
    end
  end

  def show
  end
end
