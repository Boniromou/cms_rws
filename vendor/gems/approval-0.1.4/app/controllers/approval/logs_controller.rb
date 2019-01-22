require_dependency "approval/application_controller"

module Approval
  class LogsController < ApplicationController
    def list
#      authorize :approval_management, :list_log?
      @all = params[:all].to_s == 'true'
      @remote = params[:remote].to_s == 'true'
      @target = params[:target]
      @approval_action = params[:approval_action]
      @search_by = params[:search_by]
      @request_logs = Request.get_logs_list(@target, @search_by, @approval_action, @all)
      @titles = approval_titles(@target, @approval_action) || {}
      render :layout => approval_file[:layout]
    end
  end
end
