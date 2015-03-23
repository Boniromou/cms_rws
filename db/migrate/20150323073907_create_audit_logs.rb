class CreateAuditLogs < ActiveRecord::Migration
  def change
    create_table :audit_logs do |t|
      t.string :audit_targit
      t.string :action_type
      t.string :action
      t.string :action_status
      t.string :action_error
      t.string :ip
      t.integer :action_by
      t.string :description

      t.timestamps
    end
  end
end
