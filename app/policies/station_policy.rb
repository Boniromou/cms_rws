class StationPolicy < ApplicationPolicy
  
  def list?
    is_admin? || has_permission?('station', 'list')
  end

  def create?
    is_admin? || has_permission?('station', 'create')
  end
  
  def change_status?
    is_admin? || has_permission?('station', 'change_status')
  end

  def register?
    is_admin? || has_permission?('station', 'register')
  end
  
  def unregister?
    register?
  end
end
