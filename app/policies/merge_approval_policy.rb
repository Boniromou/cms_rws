class MergeApprovalPolicy < ApplicationPolicy
  map_policy :index?, :target => :fund_transfer_approval, :action_name => :list
#  map_policy :exception_transaction_approve?, :target => :player_transaction_approval, :action_name => :approve
#  map_policy :exception_transaction_cancel_submit?, :target => :player_transaction_approval, :action_name => :reject_submit
#  map_policy :history?, :target => :player_transaction_approval, :action_name => :list_log
# def history?
#   true
# end
#  def index?
#    true
#  end
end

