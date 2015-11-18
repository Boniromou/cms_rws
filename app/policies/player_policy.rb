class PlayerPolicy < ApplicationPolicy
  def create?
    #TODO delete create permission
    is_admin? || has_permission?('player', 'create')
  end

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
    lock?
  end

  def reset_pin?
    is_admin? || has_permission?('player', 'reset_pin')
  end
end
