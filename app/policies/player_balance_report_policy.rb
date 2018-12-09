class PlayerBalanceReportPolicy < ApplicationPolicy
  policy_target :player_balance_report
  map_policy :list?
end
