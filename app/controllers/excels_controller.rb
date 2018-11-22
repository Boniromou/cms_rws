class ExcelsController < ApplicationController
  respond_to :html, :js
  def account_activities
    wallet_requester = requester_factory.get_wallet_requester
    response = wallet_requester.get_account_activity(params[:member_id], params[:start_time], params[:end_time], params[:round_id], params[:length], params[:start], "trans_date desc")
    transactions = response.success? ? response.transactions : []
    player_id = transactions.first['player_id'] if transactions.present?
    data = { transactions: transactions }
    data.merge!({member_id: params[:member_id], licensee_name: params[:licensee_name], start_time: params[:start_time], end_time: params[:end_time]}) if params[:licensee_name]
    player_id = transactions[0]['player_id'] if params[:round_id].present? && transactions.present?
    if player_id 
      player = policy_scope(Player).find_by_id(player_id)
      data.merge!({member_id: player.member_id, licensee_name: player.licensee.name, start_time: params[:start_time], end_time: params[:end_time]}) if player
    end
    file_name = I18n.t("export.account_activity_file_name")
    string_io = Excel::AccountActivitiesExportHelper.new.generate_export(data)
    send_data string_io, :filename => "#{file_name}", :type =>  "application/vnd.ms-excel"
  end
end