class ShiftPolicy < ApplicationPolicy
  def roll?
    is_admin? || has_permission?('shift', 'roll')
  end

  def search_fm?
    is_admin? || has_permission?('shift', 'search_fm')
  end

  def print_fm?
    is_admin? || has_permission?('shift', 'print_fm')
  end
end
