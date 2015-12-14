class AddActionAtToAuditLogs < ActiveRecord::Migration
  def change
    add_column :audit_logs, :action_at, :datetime
  end
end
