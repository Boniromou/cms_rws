class ShiftPolicy < ApplicationPolicy
  def roll?
    is_admin? || has_permission?('shift', 'roll')
  end

  def search_fm?
    is_admin? || has_permission?('shift', 'fm_activity_report')
  end

  def print_fm?
    is_admin? || has_permission?('shift', 'print_fm_activity_report')
  end
end
