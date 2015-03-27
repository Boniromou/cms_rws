class FundInController < ApplicationController
  layout 'cage'

  def new
    member_id = params[:member_id]
    @player = Player.find_by_member_id(member_id)
  end

  def create
    member_id = params[:player][:member_id]
    amount = params[:player_transaction][:amount].to_i * 100

    player = Player.find_by_member_id(member_id)
    player[:balance] += amount
    player.save

    @transaction = PlayerTransaction.new
    @transaction[:player_id] = player[:id]
    @transaction[:amount] = amount
    @transaction.save
  end

  def show
  end
end
