class DropLocationStationTable < ActiveRecord::Migration
  def up
    drop_table :stations
    drop_table :locations
  end

  def down
    create_table :stations do |t|
      t.string :name
      t.string :terminal_id
      t.integer :location_id
      t.string :status
      t.datetime :purge_at

      t.timestamps
    end
    create_table :locations do |t|
      t.string :name
      t.string :status
      t.datetime :purge_at

      t.timestamps
    end
    execute "ALTER TABLE stations ADD CONSTRAINT fk_location_id FOREIGN KEY (location_id) REFERENCES locations(id);"
  end
end
