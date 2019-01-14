class ApprovalManagementPolicy < ApplicationPolicy
  policy_target :approval_management
  map_policy :list_log?
  map_policy :link?, :delegate_policies => [:list_log?]
end
