class LocationPolicy < ApplicationPolicy
  def add?
    is_admin? || has_permission?('location', 'add')
  end

  def list?
    is_admin? || has_permission?('location', 'list')
  end

  def disable?
    is_admin? || has_permission?('location', 'disable')
  end

  def enable?
    disable?
  end

end
