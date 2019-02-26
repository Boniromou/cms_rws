class AddDefaultValueForStartedAt< ActiveRecord::Migration
  def up
    execute "UPDATE shifts SET started_at = created_at;"
  end

  def down
    execute "UPDATE shifts SET started_at = nil;"
  end
end
