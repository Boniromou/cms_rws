class CreateApprovalLogs < ActiveRecord::Migration
  def up
    create_table :approval_logs do |t|
      t.string  :action,    :limit => 45,  :null => false
      t.string  :action_by, :limit => 255, :null => false
      t.integer :approval_request_id, :null => false

      t.timestamps
    end

    execute "ALTER TABLE approval_logs ADD CONSTRAINT fk_approvallogs_approvalrequests FOREIGN KEY (approval_request_id) REFERENCES approval_requests(id);"
  end

  def down
  	execute "ALTER TABLE approval_logs DROP FOREIGN KEY fk_approvallogs_approvalrequests;"
    drop_table :approval_logs
  end
end
