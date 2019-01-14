require_dependency "approval/application_controller"

module Approval
  class RequestsController < ApplicationController

    ['approve', 'cancel_submit', 'cancel_approve'].each do |method_name|
      define_method method_name do

        approval_request = Request.find(params[:id])
        authorize approval_request.target.to_sym, "#{approval_request.action}_#{method_name}?".to_sym
        begin
          operation = method_name.include?('cancel') ? 'cancel' : method_name
          approval_request.send(operation, current_user.name)
          flash[:success] = I18n.t('approval.success', operation: method_name.titleize.downcase, approval_action: approval_request.action.titleize.downcase)
        rescue ApprovalUpdateStatusFailed
          flash[:alert] = I18n.t('approval.failed', operation: method_name.titleize.downcase, approval_action: approval_request.action.titleize.downcase)
        end
        redirect_to_approval_list(method_name, approval_request, params[:search_by], params[:all])
      end
    end

    def index
      requests_index(params, Approval::Request::PENDING)
    end

    def approved_index
      requests_index(params, Approval::Request::APPROVED)
    end

    private
    def requests_index(params, status)
      authorize params[:target].to_sym, "#{params[:approval_action]}_approval_list?".to_sym
      @all = params[:all].to_s == 'true'
      @target = params[:target]
      @approval_action = params[:approval_action]
      @search_by = params[:search_by]
      @requests = Request.get_requests_list(@target, @search_by, @approval_action, status, @all)
      @titles = approval_titles(@target, @approval_action) || {}
      render :layout => approval_file[:layout]
    end

    def redirect_to_approval_list(operation, approval_request, search_by, all)
      path = operation == 'cancel_approve' ? 'requests_approved_index_path' : 'index_path'
      redirect_to send(path, {target: approval_request.target, search_by: search_by, approval_action: approval_request.action, all: all})
    end
  end
end
