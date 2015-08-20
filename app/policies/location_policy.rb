class LocationPolicy < ApplicationPolicy
  def add?
    is_admin? || has_permission?('location', 'add')
  end

  def list?
    is_admin? || has_permission?('location', 'list')
  end

  def change_status?
    is_admin? || has_permission?('location', 'change_status')
  end

end
