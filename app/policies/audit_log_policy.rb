class AuditLogPolicy < ApplicationPolicy
  def search_audit_log?
    is_admin? || has_permission?('audit_log', 'search_audit_log')
  end
end
