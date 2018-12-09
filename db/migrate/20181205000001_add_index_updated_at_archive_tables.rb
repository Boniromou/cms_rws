class AddIndexUpdatedAtArchiveTables < ActiveRecord::Migration
  def self.up
    add_index :audit_logs, :updated_at, :name => 'idx_updated_at'
	add_index :change_histories, :updated_at, :name => 'idx_updated_at'
  end

  def self.down
    remove_index :change_histories, :name => 'idx_updated_at'
    remove_index :archive_logs, :name => 'idx_updated_at'
  end
end
