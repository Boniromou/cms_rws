class LocationPolicy < ApplicationPolicy
  def create?
    # is_admin? || has_permission?('location', 'create')
    return true
  end

  def list?
    return true
  end
  
  def manage?
    # is_admin? || has_permission?('location', 'create')
    return true
  end

  def disable?
    return true
  end

  def enable?
    disable?
  end

end
