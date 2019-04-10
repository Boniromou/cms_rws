class ExcelsController < ApplicationController
  include FundHelper
  respond_to :html, :js

  def account_activities
    wallet_requester = requester_factory.get_wallet_requester
    response = wallet_requester.get_account_activity(params[:member_id], params[:start_time], params[:end_time], params[:round_id], params[:length], params[:start], "trans_date desc")
    transactions = response.success? ? response.transactions : []
    player_id = transactions.first['player_id'] if transactions.present?
    data = { transactions: transactions }
    player_id = transactions[0]['player_id'] if params[:round_id].present? && transactions.present?
    if player_id
      player = policy_scope(Player).find_by_id(player_id)
      data.merge!({member_id: player.member_id, licensee_name: player.licensee.name, start_time: params[:start_time], end_time: params[:end_time]}) if player
    end
    file_name = I18n.t("export.account_activity_file_name")
    string_io = Excel::AccountActivitiesExportHelper.new.generate_export(data)
    send_data string_io, :filename => "#{file_name}", :type =>  "application/vnd.ms-excel"
  end

  def player_balance_report
    players = Player.includes(:active_lock_types).where(licensee_id: current_licensee_id).order('member_id desc')
    wallet_requester = requester_factory.get_wallet_requester
    if players.present?
      player_balances = wallet_requester.get_player_balances
      player_balances = Hash[player_balances.players.map{|player| [player['login_name'], display_balance(player['balance'])]}]
      total_balances = display_balance(wallet_requester.get_total_balances.total_balances)
    end
    file_name = I18n.t("export.player_balance_report_file_name")
    string_io = Excel::BalanceReprotExportHelper.new.generate_export(players, player_balances, total_balances)
    send_data string_io, :filename => "#{file_name}", :type =>  "application/vnd.ms-excel"
  end

  def approval_page

    record = Approval::Request.get_requests_list(params[:target], params[:search_by], params[:approval_action], params[:status], '')
    p record
    if params[:status] == 'approved'
      record2 = record.sort_by{ |hsh| hsh[:updated_at]}.reverse
      file_name = I18n.t("export.approved_merge_file_name")
      string_io = Excel::ApprovalExportHelper.new.generate_export(record2)
    else
      record2 = record.sort_by{ |hsh| hsh[:updated_at]}.reverse
      file_name = I18n.t("export.rejected_merge_file_name")
      string_io = Excel::ApprovalExportHelper.new.generate_reject_export(record2)
    end
    send_data string_io, :filename => "#{file_name}", :type =>  "application/vnd.ms-excel"    

  end
end
