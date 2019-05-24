class PlayerPolicy < ApplicationPolicy
  policy_target :player
  map_policy :lock?, :unlock?, :reset_pin?
  map_policy :balance?, :action_name => :balance_enquiry
  map_policy :merge?, :action_name => :fund_transfer
  map_policy :profile?, :action_name => :player_profile
  map_policy :create_pin?, :delegate_policies => [:reset_pin?]
  map_policy :do_reset_pin?, :delegate_policies => [:reset_pin?]
  map_policy :merge_player_approval_list?, :target => :fund_transfer_approval, :action_name => :list
  map_policy :merge_player_cancel_submit?, :target => :fund_transfer_approval, :action_name => :reject_submit
  map_policy :merge_player_approve?, :target => :fund_transfer_approval, :action_name => :approve
  
  def merge_player_approval_list?
    true
  end
  
#  def merge_player_cancel_submit?
#    true
#  end
  
#  def merge_player_approve?
#    true
#  end

  def non_test_mode?
    !@record.test_mode_player
  end
  
#  def merge?
#    true
#  end
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
