class ChangeHistoryPolicy < ApplicationPolicy
  policy_target :change_history
  map_policy :lock_player_log?, :pin_change_log?
  
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.where(:licensee_id => user.casino.licensee_id)
    end
  end
end
