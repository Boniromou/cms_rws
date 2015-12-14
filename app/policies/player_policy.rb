class PlayerPolicy < ApplicationPolicy
  policy_target :player
  map_policy :lock?, :unlock?, :reset_pin?
  map_policy :balance?, :action_name => :balance_enquiry
  map_policy :profile?, :action_name => :player_profile
end
