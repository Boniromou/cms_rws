class AuditLog < ActiveRecord::Base
  attr_accessible :action, :action_by, :action_error, :action_status, :action_type, :audit_targit, :description, :ip
end
