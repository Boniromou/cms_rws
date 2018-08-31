class AddColumnAndIndexPurgeAtToChangeHistories < ActiveRecord::Migration
  def up
    add_column :change_histories, :purge_at, :datetime
    add_index :change_histories, :purge_at, :name=>'idx_purge_at'
  end

  def down
    remove_index :change_histories, :name=>'idx_purge_at'
    remove_column :change_histories, :purge_at, :datetime
  end
end
