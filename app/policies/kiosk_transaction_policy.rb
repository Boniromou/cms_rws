class KioskTransactionPolicy < ApplicationPolicy
  policy_target :kiosk_transaction
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
  def deposit?
    have_active_location? && can_deposit?
  end

  def withdraw?
    have_active_location? && can_withdraw?
  end
end
