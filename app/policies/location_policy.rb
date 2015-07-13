class LocationPolicy < ApplicationPolicy
  def create?
    # is_admin? || has_permission?('location', 'create')
    return true
  end

  def manage?
    # is_admin? || has_permission?('location', 'create')
    return true
  end

  def change_status?
  return true
  end

end
