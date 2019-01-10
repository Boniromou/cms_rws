# This migration comes from approval (originally 20170619025447)
class ChangeDataLimitForApprovalRequests < ActiveRecord::Migration
  def up
    change_column :approval_requests, :data, :string, :limit => 4096
  end

  def down
    change_column :approval_requests, :data, :string, :limit => 1024
  end
end
