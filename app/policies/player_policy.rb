class PlayerPolicy < ApplicationPolicy
  def create?
    is_admin? || has_permission?('player', 'create')
  end

  def balance?
    is_admin? || has_permission?('player', 'balance')
  end

  def profile?
    true
  end

  def edit?
    true
  end

  def update?
    edit?
  end

  def lock?
    true
  end
end
