class AuditLog < ActiveRecord::Base
  attr_accessible :action, :action_by, :action_error, :action_status, :action_type, :audit_target, :description, :ip, :session_id

  def self.create_player
    log = new
    log.action = "create"
    log.action_by = 1
    log.action_error = ""
    log.action_status = "Success"
    log.action_type = "create"
    log.audit_target = "Player"
    log.description = "location:,shift:"
    log.ip = ""
    log.session_id = ""
    log.save
  end
end
