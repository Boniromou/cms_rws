class AccountActivityPolicy < ApplicationPolicy
  policy_target :account_activity
  map_policy :list?
end
