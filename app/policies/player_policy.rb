class PlayerPolicy < ApplicationPolicy

  def balance?
    is_admin? || has_permission?('player', 'balance_enquiry')
  end

  def profile?
    is_admin? || has_permission?('player', 'player_profile')
  end

  def lock?
    is_admin? || has_permission?('player', 'lock')
  end

  def unlock?
    is_admin? || has_permission?('player', 'unlock')
  end

  def reset_pin?
    is_admin? || has_permission?('player', 'reset_pin')
  end

end
