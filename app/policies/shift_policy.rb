class ShiftPolicy < ApplicationPolicy
  def roll?
    is_admin? || has_permission?('shift', 'roll')
  end
end
