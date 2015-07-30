class StationPolicy < ApplicationPolicy
  
  def list?
    is_admin? || has_permission?('player', 'list')
  end

  def create?
    is_admin? || has_permission?('player', 'create')
  end
  
  def change_status?
    is_admin? || has_permission?('player', 'change_status')
  end

  def register?
    is_admin? || has_permission?('player', 'register')
  end
  
  def unregister?
    register?
  end
end
