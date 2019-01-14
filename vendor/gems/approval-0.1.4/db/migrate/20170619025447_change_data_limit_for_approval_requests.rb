class ChangeDataLimitForApprovalRequests < ActiveRecord::Migration
  def up
    change_column :approval_requests, :data, :string, :limit => 4096
  end

  def down
    change_column :approval_requests, :data, :string, :limit => 1024
  end
end
