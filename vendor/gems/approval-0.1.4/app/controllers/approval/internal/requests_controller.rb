require_dependency "approval/application_controller"

module Approval
  class Internal::RequestsController < ApplicationController
    def submit
      render :json => Models.submit(params[:target], params[:target_id], params[:approval_action], params[:data], params[:current_user])
    end

    def update_status
      render :json => Models.update_status(params[:target], params[:target_id], params[:approval_action], params[:operation], params[:current_user])
    end

    def get_details
      render :json => Models.get_details(params[:target], params[:target_id], params[:approval_action])
    end

    def get_details_by_target_ids
      render :json => Models.get_details_by_target_ids(params[:target], params[:target_ids], params[:approval_action])
    end

    def get_status_by_target_ids
      render :json => Models.get_status_by_target_ids(params[:target], params[:target_ids], params[:approval_action])
    end
  end
end
