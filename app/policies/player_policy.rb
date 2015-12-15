class PlayerPolicy < ApplicationPolicy
  policy_target :player
  map_policy :lock?, :unlock?, :reset_pin?
  map_policy :balance?, :action_name => :balance_enquiry
  map_policy :profile?, :action_name => :player_profile
  map_policy :create_pin?, :delegate_policies => [:reset_pin?]
  map_policy :do_reset_pin?, :delegate_policies => [:reset_pin?]
end
