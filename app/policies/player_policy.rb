class PlayerPolicy < ApplicationPolicy
  def create?
    is_admin? || has_permission?('player', 'create')
  end

  def balance?
    is_admin? || has_permission?('player', 'balance')
  end
end
