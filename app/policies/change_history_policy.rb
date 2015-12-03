class ChangeHistoryPolicy < ApplicationPolicy
  def lock_player_log?
    is_admin? || has_permission?('change_history', 'lock_player_log')
  end

  def pin_change_log?
    is_admin? || has_permission?('change_history', 'pin_change_log')
  end
end
