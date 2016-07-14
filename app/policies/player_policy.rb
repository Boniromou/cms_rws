class PlayerPolicy < ApplicationPolicy
  policy_target :player
  map_policy :lock?, :unlock?, :reset_pin?
  map_policy :balance?, :action_name => :balance_enquiry
  map_policy :profile?, :action_name => :player_profile
  map_policy :create_pin?, :delegate_policies => [:reset_pin?]
  map_policy :do_reset_pin?, :delegate_policies => [:reset_pin?]

  def non_test_mode?
    !@record.test_mode_player
  end
  
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
