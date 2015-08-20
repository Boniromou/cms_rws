class AuditLogPolicy < ApplicationPolicy
  def search?
    is_admin? || has_permission?('audit_log', 'search')
  end
end
