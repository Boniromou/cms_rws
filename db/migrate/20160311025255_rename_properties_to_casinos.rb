class RenamePropertiesToCasinos < ActiveRecord::Migration
  def up
    rename_table :properties, :casinos
  end

  def down
    rename_table :casinos, :properties
  end
end
