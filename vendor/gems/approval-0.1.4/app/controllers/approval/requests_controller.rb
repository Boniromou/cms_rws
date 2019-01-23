require_dependency "approval/application_controller"

module Approval
  class RequestsController < ApplicationController
    rescue_from Remote::AmountNotEnough, :with => :handle_balance_not_enough
    rescue_from FundInOut::CallWalletFail, :with => :handle_call_wallet_fail
    ['approve', 'cancel_submit', 'cancel_approve'].each do |method_name|
      define_method method_name do
        @method_name = method_name
        approval_request = Request.find(params[:id])
        @approval_request = approval_request
        authorize approval_request.target.to_sym, "#{approval_request.action}_#{method_name}?".to_sym
        operation = method_name.include?('cancel') ? 'cancel' : method_name
        begin
          @Approvetransaction = ApprovalRequest.find_by_id(params[:id])
          transaction = PlayerTransaction.find_by_id(@Approvetransaction.target_id)
          player = Player.find_by_id(transaction.player_id)
          if operation == 'approve'
            data = {}
            data[:login_name] = player.member_id
            data[:amount] = transaction.amount / 100.0
            data[:ref_trans_id] = transaction.ref_trans_id
            data[:trans_date] = transaction.trans_date.localtime
            data[:source_type] = "cage_manual_transaction"
            data[:machine_token] = transaction.machine_token
            data[:casino_id] = transaction.casino_id
            data[:executed_by] = "system"
            transaction.approved_by = current_user.name
            transaction.save
            
            if JSON.parse(@Approvetransaction.data)["transaction_type"] == "Manual Deposit"
                deposit_request(data)
                approval_request.send(operation, current_user.name)
            elsif JSON.parse(@Approvetransaction.data)["transaction_type"] == "Manual Withdraw"
                withdraw_request(data)
                approval_request.send(operation, current_user.name)
            end
          elsif operation == 'cancel' 
              approval_request.send(operation, current_user.name)
              transaction.status = 'rejected'
              transaction.save
          end
          flash[:success] = I18n.t("#{operation}.success", operation: method_name.titleize.downcase, approval_action: approval_request.action.titleize.downcase)
        rescue ApprovalUpdateStatusFailed
          flash[:alert] = I18n.t("#{operation}.failed", operation: method_name.titleize.downcase, approval_action: approval_request.action.titleize.downcase)
 
        end
        redirect_to_approval_list(method_name, approval_request, params[:search_by], params[:all], true)
      end
    end
#    def initialize(requester_factory)
#      @requester_factory = requester_factory
#    end

#    def wallet_requester
#      @requester_factory.get_wallet_requester
#    end
   
    
    def index
      requests_index(params, Approval::Request::PENDING)
    end

    def approved_index
      requests_index(params, Approval::Request::APPROVED)
    end
    
    def deposit_request(data)
      player = Player.find_by_member_id_and_casino_id(data[:login_name], data[:casino_id])      
      raise Request::InvalidLoginName if player.nil?    
      p "=======Call wallet #{player.member_id}--#{player.test_mode_player}"
      balance_response = wallet_requester.get_player_balance(player.member_id, 'HKD', player.id, Currency.find_by_name('HKD').id, player.test_mode_player)
      balance = balance_response.balance
      player_transaction = PlayerTransaction.find_by_ref_trans_id(data[:ref_trans_id])
      p "=======Call End--------------------"

      raise Request::RetrieveBalanceFail unless balance.class == Float
  #   handle_processed_trans( player_transaction ) unless player_transaction.nil?
      server_amount = PlayerTransaction.to_server_amount(data[:amount])

      response = wallet_requester.deposit(data[:login_name], data[:amount], player_transaction.ref_trans_id, player_transaction.trans_date.localtime.strftime("%Y-%m-%d %H:%M:%S"), data[:source_type], nil, 'system', data[:machine_token],nil)

      after_balance = balance + PlayerTransaction.cents_to_dollar(server_amount)
      handle_wallet_result(player_transaction, response)
      {:amt => data[:amount], :trans_date => player_transaction.trans_date.localtime.strftime("%Y-%m-%d %H:%M:%S"), :balance => after_balance, :ref_trans_id => player_transaction.ref_trans_id}
    end

    def withdraw_request(data)
      player = Player.find_by_member_id_and_casino_id(data[:login_name], data[:casino_id])
      raise Request::InvalidLoginName if player.nil?
      p "=======Call wallet #{player.member_id}--#{player.test_mode_player}"
      balance_response = wallet_requester.get_player_balance(player.member_id, 'HKD', player.id, Currency.find_by_name('HKD').id, player.test_mode_player)
      balance = balance_response.balance
      player_transaction = PlayerTransaction.find_by_ref_trans_id(data[:ref_trans_id])
      p "=======Call End--------------------"
 
      raise Request::RetrieveBalanceFail unless balance.class == Float
    #   handle_processed_trans( player_transaction ) unless player_transaction.nil?
      server_amount = PlayerTransaction.to_server_amount(data[:amount])
 
      response = wallet_requester.withdraw(data[:login_name], data[:amount], player_transaction.ref_trans_id, player_transaction.trans_date.localtime.strftime("%Y-%m-%d %H:%M:%S"), data[:source_type], nil, 'system', data[:machine_token])
 
      after_balance = balance + PlayerTransaction.cents_to_dollar(server_amount)
      handle_wallet_result(player_transaction, response)
      {:amt => data[:amount], :trans_date => player_transaction.trans_date.localtime.strftime("%Y-%m-%d %H:%M:%S"), :balance => after_balance, :ref_trans_id => player_transaction.ref_trans_id}
    end 
    
    
    def handle_wallet_result(player_transaction, response)
      if !response.success?
        raise FundInOut::CallWalletFail
      else
        PlayerTransaction.transaction do
         # flash[:success] = {key: "flash_message.deposit_complete", replace: {amount: to_display_amount_str(player_transaction.amount)}}
          player_transaction.trans_date = response.trans_date
          player_transaction.completed!
        end
        #redirect_to main_app.reprint_path(transaction_id: player_transaction.id)
      end
    end



    private
    def requests_index(params, status)
      authorize params[:target].to_sym, "#{params[:approval_action]}_approval_list?".to_sym
      @all = params[:all].to_s == 'true'
      @remote = params[:remote].to_s == 'true'
      @target = params[:target]
      @approval_action = params[:approval_action]
      @search_by = params[:search_by]
      @requests = Request.get_requests_list(@target, @search_by, @approval_action, status, @all)
      @titles = approval_titles(@target, @approval_action) || {}
      render :layout => approval_file[:layout]
    end

    def redirect_to_approval_list(operation, approval_request, search_by, all, remote)
     # path = operation == 'cancel_approve' ? 'requests_approved_index_path' : 'index_path'
     # redirect_to send(path, {target: approval_request.target, search_by: search_by, approval_action: approval_request.action, all: all, remote: remote})
     action = operation == 'cancel_approve' ? 'approved_index' : 'index'
     if remote
       status = operation == 'cancel_approve' ? Approval::Request::APPROVED : Approval::Request::PENDING
       @all = all
       @remote = remote
       @target = approval_request.target
       @approval_action = approval_request.action
       @search_by = search_by
       @requests = Request.get_requests_list(@target, @search_by, @approval_action, status, @all)
       @titles = approval_titles(@target, @approval_action) || {}
       # redirect_to approval.index_path(target: 'player_transaction', search_by: search_by, approval_action: 'exception_transaction'), format: 'js'
       render "approval/requests/#{action}", :layout => approval_file[:layout], :remote => true, search_by: search_by
     else
       redirect_to url_for(controller: :requests, action: action, target: approval_request.target, search_by: search_by, approval_action: approval_request.action, all: all, remote: remote)
     end
    end

    def handle_balance_not_enough(e)
      flash[:fail] = I18n.t("flash_message.not_enough_amount")

      redirect_to_approval_list(@method_name, @approval_request, params[:search_by], params[:all], true)
    end
    
    def handle_call_wallet_fail(e)
     flash[:fail] = 'flash_message.contact_service'
     redirect_to_approval_list(@method_name, @approval_request, params[:search_by], params[:all], true)
   end
  end
end
