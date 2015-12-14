class ShiftPolicy < ApplicationPolicy
  policy_target :shift
  map_policy :roll?
  map_policy :search_fm?, :action_name => :fm_activity_report
  map_policy :print_fm?, :action_name => :print_fm_activity_report
end
