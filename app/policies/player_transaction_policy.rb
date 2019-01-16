class PlayerTransactionPolicy < ApplicationPolicy
  policy_target :player_transaction
  map_policy :print?, :action_name => :print_slip
  map_policy :search?, :action_name => :transaction_history
  map_policy :do_search?, :delegate_policies => [:search?]
  map_policy :reprint?, :action_name => :reprint_slip
  map_policy :print_report?, :action_name => :print_transaction_report
  map_policy :void?
  map_policy :void_deposit?, :delegate_policies => [:void?]
  map_policy :void_withdraw?, :delegate_policies => [:void?]
  map_policy :credit_deposit?, :action_name => :add_credit
  map_policy :credit_expire?, :action_name => :expire_credit
  map_policy :print_void?, :action_name => :print_void_slip
  map_policy :reprint_void?, :action_name => :reprint_void_slip
  map_policy :can_deposit?, :action_name => :deposit
  map_policy :can_withdraw?, :action_name => :withdraw
  map_policy :exception_transaction_approval_list?, :target => :transaction_approval,:action_name => :list
  map_policy :exception_transaction_cancel_submit?,:target => :transaction_approval, :action_name => :reject_submit
  map_policy :exception_transaction_approve?,:target => :transaction_approval, :action_name => :approve
  map_policy :exception?, :action_name => :submit_manual_transaction

 # def exception?
 #   true
 # end  
 # def exception_transaction_approve?
 #   true
 # end
  def exception_transaction_approval_list?
    true
  end
#  def exception_transaction_cancel_submit? 
#    true
#  end
  def deposit?
    have_active_location? && can_deposit?
  end

  def withdraw?
    have_active_location? && can_withdraw?
  end


  def usermatchtoken( current_casino_id, user_casino_id )
  user_casino_id.each do |casino_id|
    if casino_id.to_s == current_casino_id.to_s
      return true
    end
  end
  false
  end
end
