class AuditLogPolicy < ApplicationPolicy
  policy_target :audit_log
  map_policy :search_audit_log?
end
