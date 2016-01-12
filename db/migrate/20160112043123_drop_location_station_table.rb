class DropLocationStationTable < ActiveRecord::Migration
  def up
    drop_table :stations
    drop_table :locations
  end

  def down
    create_table :stations do |t|
      t.string :name

      t.timestamps
    end
    create_table :locations do |t|
      t.string :name

      t.timestamps
    end
  end
end
