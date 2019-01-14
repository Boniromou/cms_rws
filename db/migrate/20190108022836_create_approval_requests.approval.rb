#This migration comes from approval (originally 20160927085808)
class CreateApprovalRequests < ActiveRecord::Migration
  def change
    create_table :approval_requests do |t|
      t.string  :target,    :limit => 45, :null => false
      t.integer :target_id, :null => false
      t.string  :action,    :limit => 45, :null => false
      t.string  :data,      :limit => 1024
      t.string  :status,    :limit => 45, :null => false, :default => "pending"
    
      t.timestamps
    end
  end
end

