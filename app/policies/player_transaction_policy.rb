class PlayerTransactionPolicy < ApplicationPolicy
  def deposit?
    is_admin? || has_permission?('player_transaction', 'deposit')
  end

  def withdraw?
    is_admin? || has_permission?('player_transaction', 'withdraw')
  end

  def print?
    is_admin? || has_permission?('player_transaction', 'print')
  end
end
