class PlayerTransactionPolicy < ApplicationPolicy
  def deposit?
    (is_admin? || has_permission?('player_transaction', 'deposit')) && @user.have_active_location
  end

  def withdraw?
    (is_admin? || has_permission?('player_transaction', 'withdraw')) && @user.have_active_location
  end

  def print?
    is_admin? || has_permission?('player_transaction', 'print_slip')
  end

  def search?
    is_admin? || has_permission?('player_transaction', 'transaction_history')
  end
  
  def reprint?
    is_admin? || has_permission?('player_transaction', 'reprint_slip')
  end

  def print_report?
    is_admin? || has_permission?('player_transaction', 'print_transaction_report')
  end

  def void?
    is_admin? || has_permission?('player_transaction', 'void')
  end

  def void_deposit?
    void?
  end

  def void_withdraw?
    void?
  end

  def credit_deposit?
    is_admin? || has_permission?('player_transaction', 'add_deposit')
  end

  def credit_expire?
    is_admin? || has_permission?('player_transaction', 'expire_deposit')
  end    

  def print_void?
    is_admin? || has_permission?('player_transaction', 'print_void_slip')
  end

  def reprint_void?
    is_admin? || has_permission?('player_transaction', 'reprint_void_slip')
  end

  def credit_deposit?
    is_admin? || has_permission?('player_transaction', 'credit_deposit')
  end

  def credit_expire?
    is_admin? || has_permission?('player_transaction', 'credit_expire')
  end
end
