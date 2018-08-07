class AddColumnAndIndexPurgeAtToAuditLogs < ActiveRecord::Migration
  def up
        add_column :audit_logs, :purge_at, :datetime
    add_index :audit_logs, :purge_at, :name=>'idx_purge_at'
  end

  def down
    remove_index :audit_logs, :name=>'idx_purge_at'
        remove_column :audit_logs, :purge_at, :datetime
  end
end

