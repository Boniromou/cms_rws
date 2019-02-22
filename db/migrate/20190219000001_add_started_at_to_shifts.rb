class AddStartedAtToShifts< ActiveRecord::Migration
  def up
    add_column :shifts, :started_at, :datetime
  end

  def down
    remove_column :shifts, :started_at
  end
end
