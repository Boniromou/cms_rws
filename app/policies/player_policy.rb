class PlayerPolicy < ApplicationPolicy
  def create?
    is_admin? || has_permission?('player', 'create')
  end

  def balance?
    is_admin? || has_permission?('player', 'balance')
  end

  def profile?
    is_admin? || has_permission?('player', 'profile')
  end

  def edit?
    is_admin? || has_permission?('player', 'edit')
  end

  def update?
    edit?
  end

  def lock?
    is_admin? || has_permission?('player', 'lock')
  end
end
