class PlayerTransactionApprovalPolicy < ApplicationPolicy
  map_policy :index?, :target => :player_transaction_approval, :action_name => :list
#  map_policy :exception_transaction_approve?, :target => :player_transaction_approval, :action_name => :approve
#  map_policy :exception_transaction_cancel_submit?, :target => :player_transaction_approval, :action_name => :reject_submit
  map_policy :history?, :target => :player_transaction_approval, :action_name => :list_log
 def exception_transaction_approve?
   false
 end
 def history?
   true
 end
 def index?
   true
 end

 def exception_transaction_cancel_submit?
   false
 end

end
