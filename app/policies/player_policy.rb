class PlayerPolicy < ApplicationPolicy
  def create?
    is_admin? || has_permission?('Player', 'create')
  end
end
