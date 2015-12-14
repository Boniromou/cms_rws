class ChangeHistoryPolicy < ApplicationPolicy
  policy_target :change_history
  map_policy :lock_player_log?, :pin_change_log?
end
