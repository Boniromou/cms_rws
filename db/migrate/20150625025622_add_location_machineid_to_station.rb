class AddLocationMachineidToStation < ActiveRecord::Migration
  def up
    add_column :stations, :machine_id, :string
    add_column :stations, :location_id, :int
    
    execute "ALTER TABLE stations ADD CONSTRAINT fk_location_id FOREIGN KEY (location_id) REFERENCES locations(id);"
  end

  def down
    execute "ALTER TABLE stations DROP FOREIGN KEY fk_location_id;"
    remove_column :stations, :machine_id
    remove_column :stations, :location_id
    
  end
end
