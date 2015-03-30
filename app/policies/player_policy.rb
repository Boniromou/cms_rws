class PlayerPolicy < ApplicationPolicy
  def create?
    is_admin? || has_permission?('Player', 'create')
  end

  def balance?
    p "check balance"
    is_admin? || has_permission?('Player', 'balance')
  end
end
