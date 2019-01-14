class TransactionApprovalsController < ApplicationController

  def index
    redirect_to approval.index_path(target: 'player_transaction', search_by: search_by, approval_action: 'exception_transaction')
  end

  def list_log
    redirect_to approval.logs_list_path(target: 'player_transcation', search_by: search_by, approval_action: 'exception_transaction')
  end

  def show
    authorize :property_game_config, :set_rtp_approval_list?
    @game = Game.includes(:property_game_configs => [:property]).where( property_game_configs: {game_id: params[:id], property_id: params[:property_id]} ).first.decorate
    @request_detail = RtpService.new(params).list_request_detail
    render :layout => false
  end

  private

  def search_by
    { casino_id: current_user.casino_ids 
    }
  end

  def all?
    current_user.has_admin_property?
  end
end
